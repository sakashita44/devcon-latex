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
#   - LATEXPAND_OPTIONS (配列) ※--expand-bblは使用しないでください
#   - LATEXPAND_EXPAND_BBL (0 or 1): --expand-bblオプションの使用制御
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
    local out_dir="$2"  # 明示的に出力ディレクトリを指定
    local tex_dir="$(dirname "$tex_file")"
    local tex_name="$(basename "$tex_file" .tex)"

    local bbl_source="$out_dir/$tex_name.bbl"
    local bbl_dest="$tex_dir/$tex_name.bbl"

    if [ -f "$bbl_source" ] && [ ! -f "$bbl_dest" ]; then
        cp "$bbl_source" "$bbl_dest"
        echo "Copied .bbl file: $bbl_source -> $bbl_dest"
        echo "$bbl_dest" >> "/tmp/bbl_cleanup_$$"
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

# latexdiffのフォールバック機能
try_latexdiff_with_fallback() {
    local base_file="$1"
    local changed_file="$2"
    local output_file="$3"

    # レベル1: config設定オプション
    echo "Trying latexdiff with config options..."
    if latexdiff "${LATEXDIFF_OPTIONS[@]}" "$base_file" "$changed_file" > "$output_file" 2>/dev/null; then
        echo "✅ latexdiff succeeded with config options"
        return 0
    fi
    echo "❌ latexdiff failed with config options, trying basic Japanese options..."

    # レベル2: 基本日本語対応
    local basic_opts=("--type=CFONT" "--encoding=utf8")
    if latexdiff "${basic_opts[@]}" "$base_file" "$changed_file" > "$output_file" 2>/dev/null; then
        echo "✅ latexdiff succeeded with basic Japanese options"
        return 0
    fi
    echo "❌ latexdiff failed with basic options, trying safe options..."

    # レベル3: 保守的設定（セクション・数式対応）
    local safe_opts=("--type=CFONT" "--encoding=utf8" "--exclude-textcmd=section,subsection,subsubsection" "--math-markup=whole")
    if latexdiff "${safe_opts[@]}" "$base_file" "$changed_file" > "$output_file" 2>/dev/null; then
        echo "✅ latexdiff succeeded with safe options"
        return 0
    fi
    echo "❌ latexdiff failed with safe options, trying safest options..."

    # レベル4: 最保守的設定（数式無視）
    local safest_opts=("--type=CFONT" "--encoding=utf8" "--exclude-textcmd=section,subsection,subsubsection" "--math-markup=off")
    if latexdiff "${safest_opts[@]}" "$base_file" "$changed_file" > "$output_file" 2>/dev/null; then
        echo "✅ latexdiff succeeded with safest options (math markup disabled)"
        return 0
    fi

    echo "❌ ERROR: latexdiff failed with all option combinations" >&2
    return 1
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

# LATEXPAND_EXPAND_BBL設定の検証 (0 or 1のみ許可)
LATEXPAND_EXPAND_BBL=${LATEXPAND_EXPAND_BBL:-0}
if [[ ! "$LATEXPAND_EXPAND_BBL" =~ ^[01]$ ]]; then
    echo "Error: LATEXPAND_EXPAND_BBL must be 0 or 1, got: $LATEXPAND_EXPAND_BBL" >&2
    exit 1
fi

# LATEXPAND_OPTIONSに--expand-bblが含まれていないかチェック
for opt in "${LATEXPAND_OPTIONS[@]}"; do
    if [[ "$opt" == "--expand-bbl" ]]; then
        echo "Error: --expand-bbl should not be specified in LATEXPAND_OPTIONS." >&2
        echo "Use LATEXPAND_EXPAND_BBL=1 instead." >&2
        exit 1
    fi
done

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
BASE_OUT_DIR="$TMP_DIR/base/out"
mkdir -p "$BASE_OUT_DIR"
if [ -n "$BASE_LATEXMKRC" ]; then
    echo "Using .latexmkrc: $BASE_LATEXMKRC"
    if ! latexmk -cd -r "$BASE_LATEXMKRC" -output-directory="$BASE_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$BASE_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for BASE side" >&2
        exit 6
    fi
else
    echo "No .latexmkrc found, using default latexmk"
    if ! latexmk -cd -output-directory="$BASE_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$BASE_TEX_ABS" 2>&1; then
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
CHANGED_OUT_DIR="$TMP_DIR/changed/out"
mkdir -p "$CHANGED_OUT_DIR"
if [ -n "$CHANGED_LATEXMKRC" ]; then
    echo "Using .latexmkrc: $CHANGED_LATEXMKRC"
    if ! latexmk -cd -r "$CHANGED_LATEXMKRC" -output-directory="$CHANGED_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$CHANGED_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for CHANGED side" >&2
        exit 6
    fi
else
    echo "No .latexmkrc found, using default latexmk"
    if ! latexmk -cd -output-directory="$CHANGED_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$CHANGED_TEX_ABS" 2>&1; then
        echo "Error: latexmk failed for CHANGED side" >&2
        exit 6
    fi
fi

# .bblファイルの準備（.latexmkrcからout_dirを検出してコピー）
echo "=== Preparing .bbl files for latexpand ==="

echo "Preparing BASE .bbl file..."
prepare_bbl_files "$BASE_TEX_ABS" "$BASE_OUT_DIR"

echo "Preparing CHANGED .bbl file..."
prepare_bbl_files "$CHANGED_TEX_ABS" "$CHANGED_OUT_DIR"

echo "✅ .bbl file preparation completed"

# === .tex ファイルの展開 (latexpand) ===
echo "=== Expanding .tex files with latexpand ==="

# BASE側展開
echo "Expanding BASE side..."
cd "$BASE_DIR" || exit 7
echo "Current directory: $(pwd)"
BASE_FILENAME=$(basename "$TARGET_BASE")
echo "Target file: $BASE_FILENAME"

# --expand-bbl オプションの処理
EXPANDED_OPTIONS=("${LATEXPAND_OPTIONS[@]}")
if [[ "$LATEXPAND_EXPAND_BBL" == "1" ]]; then
    BASE_BBL_FILE="$BASE_DIR/$(basename "$BASE_FILENAME" .tex).bbl"
    EXPANDED_OPTIONS+=("--expand-bbl" "$BASE_BBL_FILE")
fi

if ! latexpand "${EXPANDED_OPTIONS[@]}" "$BASE_FILENAME" > "$TMP_DIR/base-expand.tex" 2>&1; then
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

# --expand-bbl オプションの処理
EXPANDED_OPTIONS=("${LATEXPAND_OPTIONS[@]}")
if [[ "$LATEXPAND_EXPAND_BBL" == "1" ]]; then
    CHANGED_BBL_FILE="$CHANGED_DIR/$(basename "$CHANGED_FILENAME" .tex).bbl"
    EXPANDED_OPTIONS+=("--expand-bbl" "$CHANGED_BBL_FILE")
fi

if ! latexpand "${EXPANDED_OPTIONS[@]}" "$CHANGED_FILENAME" > "$TMP_DIR/changed-expand.tex" 2>&1; then
    echo "Error: latexpand failed for CHANGED side" >&2
    exit 7
fi
echo "CHANGED expansion output size: $(wc -l < "$TMP_DIR/changed-expand.tex") lines"

echo "✅ LaTeX expansion completed"

# === 差分.tex ファイルの生成 (latexdiff) ===
echo "=== Generating diff.tex with latexdiff ==="

if ! try_latexdiff_with_fallback "$TMP_DIR/base-expand.tex" "$TMP_DIR/changed-expand.tex" "$TMP_DIR/diff.tex"; then
    echo "Error: latexdiff failed with all fallback options" >&2
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
    if ! latexmk -cd -r "$CHANGED_LATEXMKRC" -output-directory="$CHANGED_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$DIFF_TEX_TARGET" 2>&1; then
        echo "Error: latexmk failed for diff.tex" >&2
        exit 9
    fi
else
    echo "Building diff.pdf with default latexmk"
    if ! latexmk -cd -output-directory="$CHANGED_OUT_DIR" "${LATEXMK_OPTIONS[@]}" "$DIFF_TEX_TARGET" 2>&1; then
        echo "Error: latexmk failed for diff.tex" >&2
        exit 9
    fi
fi

# 生成されたPDFを出力ディレクトリにコピー
DIFF_PDF_SOURCE="$CHANGED_OUT_DIR/diff.pdf"
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
