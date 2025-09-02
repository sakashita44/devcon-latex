#!/usr/bin/env bash
set -euo pipefail

#
# 概要: 2つのリビジョンの.texファイルから、差分PDFを生成する。
#       .bblファイルの事前生成により、参考文献の差分精度を向上させる。
#
# 引数:
#   $1: TARGET_BASE (BASE側の.texファイルパス)
#   $2: TARGET_CHANGED (CHANGED側の.texファイルパス)
#   $3: BASE_REPO_PATH (BASE側のワークツリーパス)
#   $4: CHANGED_REPO_PATH (CHANGED側のワークツリーパス)
#   $5: DIFF_OUT_DIR (成果物の出力先ディレクトリ)
#
# 依存設定 (config):
#   - LATEXMK_OPTIONS (配列)
#   - LATEXPAND_OPTIONS (配列)
#   - LATEXDIFF_OPTIONS (配列)
#

# common.shとconfig読み込み
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../common.sh"
load_config

# .bblファイル管理用の関数群
detect_out_dir() {
    local tex_dir="$1"
    local latexmkrc="$tex_dir/.latexmkrc"
    if [ -f "$latexmkrc" ]; then
        grep -E '^\s*\$out_dir\s*=' "$latexmkrc" | \
        sed -E "s/.*\\\$out_dir\s*=\s*['\"]([^'\"]*)['\"].*;.*/\1/" | \
        head -1
    fi
}

prepare_bbl_files() {
    local tex_file="$1"
    local tex_dir="$(dirname "$tex_file")"
    local tex_name="$(basename "$tex_file" .tex)"

    local out_dir=$(detect_out_dir "$tex_dir")
    if [ -n "$out_dir" ]; then
        local bbl_source="$tex_dir/$out_dir/$tex_name.bbl"
        local bbl_dest="$tex_dir/$tex_name.bbl"

        if [ -f "$bbl_source" ] && [ ! -f "$bbl_dest" ]; then
            cp "$bbl_source" "$bbl_dest"
            echo "Copied .bbl file: $bbl_source -> $bbl_dest"
            echo "$bbl_dest" >> "/tmp/bbl_cleanup_$$"
        fi
    fi
}

cleanup_bbl_files() {
    if [ -f "/tmp/bbl_cleanup_$$" ]; then
        while read -r bbl_file; do
            if [ -f "$bbl_file" ]; then
                rm "$bbl_file"
                echo "Cleaned up: $bbl_file"
            fi
        done < "/tmp/bbl_cleanup_$$"
        rm "/tmp/bbl_cleanup_$$"
    fi
}

# スクリプト終了時の確実なクリーンアップ
trap cleanup_bbl_files EXIT

# === 引数チェック ===
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_BASE> <TARGET_CHANGED> <BASE_REPO_PATH> <CHANGED_REPO_PATH> <DIFF_OUT_DIR>" >&2
    exit 1
fi

TARGET_BASE=$1
TARGET_CHANGED=$2
BASE_REPO_PATH=$3
CHANGED_REPO_PATH=$4
DIFF_OUT_DIR=$5

# === 初期設定 ===
echo "Starting PDF diff generation..."
echo "TARGET_BASE: $TARGET_BASE"
echo "TARGET_CHANGED: $TARGET_CHANGED"
echo "BASE_REPO_PATH: $BASE_REPO_PATH"
echo "CHANGED_REPO_PATH: $CHANGED_REPO_PATH"
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR"

# 配列変数の安全化（common.shのload_configで既に処理済みだが、明示的に確認）
declare -a LATEXMK_OPTIONS=${LATEXMK_OPTIONS-()}
declare -a LATEXPAND_OPTIONS=${LATEXPAND_OPTIONS-()}
declare -a LATEXDIFF_OPTIONS=${LATEXDIFF_OPTIONS-()}

# 作業用一時ディレクトリ
TMP_DIR="$DIFF_OUT_DIR/tmp"
mkdir -p "$TMP_DIR"

# === ファイル存在チェック ===
if [ ! -f "$BASE_REPO_PATH/$TARGET_BASE" ]; then
    echo "Error: BASE target file not found: $BASE_REPO_PATH/$TARGET_BASE" >&2
    exit 2
fi

if [ ! -f "$CHANGED_REPO_PATH/$TARGET_CHANGED" ]; then
    echo "Error: CHANGED target file not found: $CHANGED_REPO_PATH/$TARGET_CHANGED" >&2
    exit 2
fi

# === .bbl ファイルの事前生成 ===
echo "=== Generating .bbl files ==="

# BASE側でlatexmk実行
echo "Building BASE side for .bbl generation..."
BASE_TEX_ABS="$BASE_REPO_PATH/$TARGET_BASE"
BASE_DIR=$(dirname "$BASE_TEX_ABS")

# .latexmkrcの探索
BASE_LATEXMKRC=""
if [ -f "$BASE_DIR/.latexmkrc" ]; then
    BASE_LATEXMKRC="$BASE_DIR/.latexmkrc"
else
    # 上位ディレクトリを探索
    SEARCH_DIR="$BASE_DIR"
    for i in $(seq 1 "${LATEXMKRC_EXPLORATION_RANGE:-3}"); do
        SEARCH_DIR=$(dirname "$SEARCH_DIR")
        if [ -f "$SEARCH_DIR/.latexmkrc" ]; then
            BASE_LATEXMKRC="$SEARCH_DIR/.latexmkrc"
            break
        fi
    done
fi

# BASE側ビルド
if [ -n "$BASE_LATEXMKRC" ]; then
    echo "Using .latexmkrc: $BASE_LATEXMKRC"
    if ! latexmk -cd -r "$BASE_LATEXMKRC" "${LATEXMK_OPTIONS[@]}" "$BASE_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for BASE side" >&2
        exit 6
    fi
else
    echo "No .latexmkrc found, using default latexmk"
    if ! latexmk -cd "${LATEXMK_OPTIONS[@]}" "$BASE_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for BASE side" >&2
        exit 6
    fi
fi

# CHANGED側でlatexmk実行
echo "Building CHANGED side for .bbl generation..."
CHANGED_TEX_ABS="$CHANGED_REPO_PATH/$TARGET_CHANGED"
CHANGED_DIR=$(dirname "$CHANGED_TEX_ABS")

# .latexmkrcの探索
CHANGED_LATEXMKRC=""
if [ -f "$CHANGED_DIR/.latexmkrc" ]; then
    CHANGED_LATEXMKRC="$CHANGED_DIR/.latexmkrc"
else
    # 上位ディレクトリを探索
    SEARCH_DIR="$CHANGED_DIR"
    for i in $(seq 1 "${LATEXMKRC_EXPLORATION_RANGE:-3}"); do
        SEARCH_DIR=$(dirname "$SEARCH_DIR")
        if [ -f "$SEARCH_DIR/.latexmkrc" ]; then
            CHANGED_LATEXMKRC="$SEARCH_DIR/.latexmkrc"
            break
        fi
    done
fi

# CHANGED側ビルド
if [ -n "$CHANGED_LATEXMKRC" ]; then
    echo "Using .latexmkrc: $CHANGED_LATEXMKRC"
    if ! latexmk -cd -r "$CHANGED_LATEXMKRC" "${LATEXMK_OPTIONS[@]}" "$CHANGED_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for CHANGED side" >&2
        exit 6
    fi
else
    echo "No .latexmkrc found, using default latexmk"
    if ! latexmk -cd "${LATEXMK_OPTIONS[@]}" "$CHANGED_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for CHANGED side" >&2
        exit 6
    fi
fi

# .bblファイルの存在確認
BASE_TEX_DIR=$(dirname "$BASE_TEX_ABS")
CHANGED_TEX_DIR=$(dirname "$CHANGED_TEX_ABS")
BASE_BBL="$BASE_REPO_PATH/out/$(basename "$TARGET_BASE" .tex).bbl"
CHANGED_BBL="$CHANGED_REPO_PATH/out/$(basename "$TARGET_CHANGED" .tex).bbl"

echo "Checking for .bbl files..."
echo "Expected BASE .bbl: $BASE_BBL"
echo "Expected CHANGED .bbl: $CHANGED_BBL"

if [ ! -f "$BASE_BBL" ] && [ ! -f "$CHANGED_BBL" ]; then
    echo "Warning: No .bbl files generated (both missing). Continuing without bibliography processing."
elif [ ! -f "$BASE_BBL" ]; then
    echo "Warning: BASE .bbl file missing: $BASE_BBL"
elif [ ! -f "$CHANGED_BBL" ]; then
    echo "Warning: CHANGED .bbl file missing: $CHANGED_BBL"
else
    echo "✅ Both .bbl files generated successfully"
fi

# === .tex ファイルの展開 (latexpand) ===
echo "=== Expanding .tex files with latexpand ==="

# BASE側展開
echo "Expanding BASE side..."
cd "$BASE_DIR" || exit 7
echo "Current directory: $(pwd)"
BASE_FILENAME=$(basename "$TARGET_BASE")
echo "Target file: $BASE_FILENAME"
if ! latexpand "${LATEXPAND_OPTIONS[@]}" "$BASE_FILENAME" > "$TMP_DIR/base-expand.tex" 2>&1; then
    echo "Error: latexpand failed for BASE side" >&2
    echo "Error details:" >&2
    cat "$TMP_DIR/base-expand.tex" >&2
    exit 7
fi
echo "BASE expansion output size: $(wc -l < "$TMP_DIR/base-expand.tex") lines"

# CHANGED側展開
echo "Expanding CHANGED side..."
cd "$CHANGED_DIR" || exit 7
CHANGED_FILENAME=$(basename "$TARGET_CHANGED")
echo "Target file: $CHANGED_FILENAME"
if ! latexpand "${LATEXPAND_OPTIONS[@]}" "$CHANGED_FILENAME" > "$TMP_DIR/changed-expand.tex" 2>&1; then
    echo "Error: latexpand failed for CHANGED side" >&2
    exit 7
fi
echo "CHANGED expansion output size: $(wc -l < "$TMP_DIR/changed-expand.tex") lines"

echo "✅ LaTeX expansion completed"

# === 差分.tex ファイルの生成 (latexdiff) ===
echo "=== Generating diff.tex with latexdiff ==="

if ! latexdiff "${LATEXDIFF_OPTIONS[@]}" "$TMP_DIR/base-expand.tex" "$TMP_DIR/changed-expand.tex" > "$TMP_DIR/diff.tex" 2>&1; then
    echo "Error: latexdiff failed" >&2
    exit 8
fi

echo "✅ Diff.tex generated successfully"

# === 差分PDFのビルド ===
echo "=== Building diff PDF ==="

# diff.texをCHANGED側のワークツリーに配置
DIFF_TEX_TARGET="$CHANGED_DIR/diff.tex"
cp "$TMP_DIR/diff.tex" "$DIFF_TEX_TARGET"

echo "Copied diff.tex to: $DIFF_TEX_TARGET"

# CHANGED側でdiff.texをビルド
if [ -n "$CHANGED_LATEXMKRC" ]; then
    echo "Building diff.pdf with .latexmkrc: $CHANGED_LATEXMKRC"
    if ! latexmk -cd -r "$CHANGED_LATEXMKRC" "${LATEXMK_OPTIONS[@]}" "$DIFF_TEX_TARGET" 2>&1; then
        echo "Error: latexmk failed for diff.tex" >&2
        exit 9
    fi
else
    echo "Building diff.pdf with default latexmk"
    if ! latexmk -cd "${LATEXMK_OPTIONS[@]}" "$DIFF_TEX_TARGET" 2>&1; then
        echo "Error: latexmk failed for diff.tex" >&2
        exit 9
    fi
fi

# 生成されたPDFを出力ディレクトリにコピー
DIFF_PDF_SOURCE="$CHANGED_DIR/diff.pdf"
DIFF_PDF_TARGET="$DIFF_OUT_DIR/main-diff.pdf"

if [ ! -f "$DIFF_PDF_SOURCE" ]; then
    echo "Error: diff.pdf was not generated: $DIFF_PDF_SOURCE" >&2
    exit 10
fi

cp "$DIFF_PDF_SOURCE" "$DIFF_PDF_TARGET"
echo "✅ Diff PDF saved to: $DIFF_PDF_TARGET"

# === 結果の報告 ===
echo "✅ PDF diff generation completed successfully"
echo "Output: $DIFF_PDF_TARGET"
