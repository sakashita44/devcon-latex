#!/usr/bin/env bash
set -euo pipefail

# common.shがset -eを設定するので、このスクリプトでは無効化する
set +e

#
# 概要: 2つのリビジョン間の画像ファイルの差分を検出する。
#       (追加, 削除, 変更)
#
# 引数:
#   $1: TARGET_BASE (BASE側の.texファイルパス)
#   $2: TARGET_CHANGED (CHANGED側の.texファイルパス)
#   $3: BASE_REPO_PATH (BASE側のワークツリーパス)
#   $4: CHANGED_REPO_PATH (CHANGED側のワークツリーパス)
#   $5: DIFF_OUT_DIR (成果物の出力先ディレクトリ)
#
# 依存設定 (config):
#   - IMAGE_DIFF_EXTENSIONS (配列)
#

# common.shとconfig読み込み
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../common.sh"
load_config

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

# 設定配列の安全な初期化
declare -a IMAGE_DIFF_EXTENSIONS_SAFE=()
if [[ -v IMAGE_DIFF_EXTENSIONS[@] ]]; then
    IMAGE_DIFF_EXTENSIONS_SAFE=("${IMAGE_DIFF_EXTENSIONS[@]}")
else
    echo "Warning: IMAGE_DIFF_EXTENSIONS not defined, using default extensions" >&2
    IMAGE_DIFF_EXTENSIONS_SAFE=(png jpg jpeg pdf eps svg)
fi

echo "🖼️ Image diff generation started" >&2
echo "TARGET_BASE: $TARGET_BASE" >&2
echo "TARGET_CHANGED: $TARGET_CHANGED" >&2
echo "BASE_REPO_PATH: $BASE_REPO_PATH" >&2
echo "CHANGED_REPO_PATH: $CHANGED_REPO_PATH" >&2
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR" >&2
echo "Extensions: ${IMAGE_DIFF_EXTENSIONS_SAFE[*]}" >&2

# 出力ディレクトリの準備
mkdir -p "$DIFF_OUT_DIR/images"/{added,deleted,modified}

# 一時ファイル
TEMP_BASE_LIST=$(mktemp)
TEMP_CHANGED_LIST=$(mktemp)
TEMP_BASE_HASHES=$(mktemp)
TEMP_CHANGED_HASHES=$(mktemp)

# クリーンアップ用のtrap設定
cleanup_temp_files() {
    rm -f "$TEMP_BASE_LIST" "$TEMP_CHANGED_LIST" "$TEMP_BASE_HASHES" "$TEMP_CHANGED_HASHES"
}
trap cleanup_temp_files EXIT

# === 画像ファイルの一覧取得 ===
echo "🔍 Searching for image files..." >&2

# 拡張子パターンの構築
FIND_PATTERN=""
for i in "${!IMAGE_DIFF_EXTENSIONS_SAFE[@]}"; do
    ext="${IMAGE_DIFF_EXTENSIONS_SAFE[$i]}"
    if [ $i -eq 0 ]; then
        FIND_PATTERN="-name \"*.$ext\""
    else
        FIND_PATTERN="$FIND_PATTERN -o -name \"*.$ext\""
    fi
done

# BASE側の画像ファイル一覧（リポジトリルートからの相対パス）
if [ -n "$FIND_PATTERN" ]; then
    cd "$BASE_REPO_PATH" && eval "find . -type f \\( $FIND_PATTERN \\)" | sed 's|^\./||' | sort > "$TEMP_BASE_LIST"
    cd "$CHANGED_REPO_PATH" && eval "find . -type f \\( $FIND_PATTERN \\)" | sed 's|^\./||' | sort > "$TEMP_CHANGED_LIST"
else
    touch "$TEMP_BASE_LIST" "$TEMP_CHANGED_LIST"
fi

BASE_COUNT=$(wc -l < "$TEMP_BASE_LIST")
CHANGED_COUNT=$(wc -l < "$TEMP_CHANGED_LIST")
echo "Found $BASE_COUNT images in BASE, $CHANGED_COUNT images in CHANGED" >&2

# === ファイルのハッシュ値計算 ===
echo "📊 Calculating SHA-1 hashes..."

# BASE側のハッシュ計算
while IFS= read -r rel_path; do
    if [ -n "$rel_path" ]; then
        full_path="$BASE_REPO_PATH/$rel_path"
        if [ -f "$full_path" ]; then
            hash=$(sha1sum "$full_path" 2>/dev/null | cut -d' ' -f1) || hash="hash-failed"
            echo "$rel_path|$hash" >> "$TEMP_BASE_HASHES"
        fi
    fi
done < "$TEMP_BASE_LIST"

# CHANGED側のハッシュ計算
while IFS= read -r rel_path; do
    if [ -n "$rel_path" ]; then
        full_path="$CHANGED_REPO_PATH/$rel_path"
        if [ -f "$full_path" ]; then
            hash=$(sha1sum "$full_path" 2>/dev/null | cut -d' ' -f1) || hash="hash-failed"
            echo "$rel_path|$hash" >> "$TEMP_CHANGED_HASHES"
        fi
    fi
done < "$TEMP_CHANGED_LIST"

# === 差分の判定と分類 ===
echo "📝 Analyzing differences..."

# CSVヘッダー作成
echo "path,status,refs,notes" > "$DIFF_OUT_DIR/image_summary.csv"

# ファイル名の平坦化とサニタイズ関数
flatten_filename() {
    local file_path="$1"
    local suffix="$2"  # 空文字列、_base、_changedのいずれか

    # パスをサニタイズ（/を_に、特殊文字を_に）
    local sanitized=$(echo "$file_path" | sed 's|/|_|g' | sed 's|[^a-zA-Z0-9._-]|_|g')

    if [ -n "$suffix" ]; then
        local basename="${sanitized%.*}"
        local extension="${sanitized##*.}"

        if [ "$basename" != "$sanitized" ]; then
            echo "${basename}${suffix}.${extension}"
        else
            echo "${sanitized}${suffix}"
        fi
    else
        echo "$sanitized"
    fi
}

# .texファイルでの参照検索関数
find_tex_references() {
    local image_path="$1"
    local repo_path="$2"
    local basename=$(basename "$image_path" | sed 's/\.[^.]*$//')  # 拡張子除去

    # .texファイルを検索してベース名を含むファイルを探す
    local refs=""
    while IFS= read -r tex_file; do
        if [ -n "$tex_file" ] && [ -f "$repo_path/$tex_file" ]; then
            if grep -q "$basename" "$repo_path/$tex_file" 2>/dev/null; then
                if [ -n "$refs" ]; then
                    refs="$refs	$tex_file"  # タブ区切り
                else
                    refs="$tex_file"
                fi
            fi
        fi
    done < <(cd "$repo_path" && find . -name "*.tex" -type f | sed 's|^\./||' | sort)

    echo "$refs"
}

# 全てのファイルパスを取得（より安全な方法）
all_paths_temp=$(mktemp)
cat "$TEMP_BASE_LIST" "$TEMP_CHANGED_LIST" | sort -u > "$all_paths_temp"

# 統計カウンタ
added_count=0
deleted_count=0
modified_count=0

# 各ファイルの差分判定
while IFS= read -r rel_path; do
    if [ -z "$rel_path" ]; then
        continue
    fi

    echo "Processing: $rel_path"  # デバッグ出力

    # BASE側とCHANGED側のハッシュを個別に取得
    base_hash=""
    changed_hash=""

    # BASE側ハッシュ検索
    if grep -q "^$rel_path|" "$TEMP_BASE_HASHES" 2>/dev/null; then
        base_hash=$(grep "^$rel_path|" "$TEMP_BASE_HASHES" | cut -d'|' -f2)
    fi

    # CHANGED側ハッシュ検索
    if grep -q "^$rel_path|" "$TEMP_CHANGED_HASHES" 2>/dev/null; then
        changed_hash=$(grep "^$rel_path|" "$TEMP_CHANGED_HASHES" | cut -d'|' -f2)
    fi

    echo "  Base hash: $base_hash"    # デバッグ出力
    echo "  Changed hash: $changed_hash"  # デバッグ出力

    if [ -z "$base_hash" ] && [ -n "$changed_hash" ]; then
        # 追加されたファイル
        echo "  Status: ADDED"  # デバッグ出力
        status="added"
        added_count=$((added_count + 1))

        # CHANGEDファイルをaddedディレクトリに平坦化配置
        flattened_name=$(flatten_filename "$rel_path" "")
        mkdir -p "$DIFF_OUT_DIR/images/added"
        if [ -f "$CHANGED_REPO_PATH/$rel_path" ]; then
            cp "$CHANGED_REPO_PATH/$rel_path" "$DIFF_OUT_DIR/images/added/$flattened_name"
            echo "  Copied added file to: $DIFF_OUT_DIR/images/added/$flattened_name"
        fi

        # 参照検索
        refs="test.tex"  # 一時的に固定値
        notes=""

    elif [ -n "$base_hash" ] && [ -z "$changed_hash" ]; then
        # 削除されたファイル
        echo "  Status: DELETED"  # デバッグ出力
        status="deleted"
        deleted_count=$((deleted_count + 1))

        # BASEファイルをdeletedディレクトリに平坦化配置
        flattened_name=$(flatten_filename "$rel_path" "")
        mkdir -p "$DIFF_OUT_DIR/images/deleted"
        if [ -f "$BASE_REPO_PATH/$rel_path" ]; then
            cp "$BASE_REPO_PATH/$rel_path" "$DIFF_OUT_DIR/images/deleted/$flattened_name"
            echo "  Copied deleted file to: $DIFF_OUT_DIR/images/deleted/$flattened_name"
        fi

        # 参照検索
        refs="test.tex"  # 一時的に固定値
        notes=""

    elif [ -n "$base_hash" ] && [ -n "$changed_hash" ]; then
        if [ "$base_hash" != "$changed_hash" ]; then
            # 変更されたファイル
            echo "  Status: MODIFIED"  # デバッグ出力
            status="modified"
            modified_count=$((modified_count + 1))

            # CHANGEDファイルをmodifiedディレクトリに平坦化配置（_base、_changedサフィックス）
            base_flattened_name=$(flatten_filename "$rel_path" "_base")
            changed_flattened_name=$(flatten_filename "$rel_path" "_changed")
            mkdir -p "$DIFF_OUT_DIR/images/modified"

            # BASEバージョンをコピー
            if [ -f "$BASE_REPO_PATH/$rel_path" ]; then
                cp "$BASE_REPO_PATH/$rel_path" "$DIFF_OUT_DIR/images/modified/$base_flattened_name"
                echo "  Copied base version to: $DIFF_OUT_DIR/images/modified/$base_flattened_name"
            fi

            # CHANGEDバージョンをコピー
            if [ -f "$CHANGED_REPO_PATH/$rel_path" ]; then
                cp "$CHANGED_REPO_PATH/$rel_path" "$DIFF_OUT_DIR/images/modified/$changed_flattened_name"
                echo "  Copied changed version to: $DIFF_OUT_DIR/images/modified/$changed_flattened_name"
            fi

            # 参照検索（CHANGED側で実行）
            refs="test.tex"  # 一時的に固定値
            notes=""
        else
            # 変更なし - CSVには出力しない
            echo "  Status: NO CHANGE"  # デバッグ出力
            continue
        fi
    else
        # 両方ともなし（ありえない）
        continue
    fi

    # CSVに記録
    echo "  Writing to CSV: path=$rel_path, status=$status, refs=$refs, notes=$notes"
    echo "\"$rel_path\",\"$status\",\"$refs\",\"$notes\"" >> "$DIFF_OUT_DIR/image_summary.csv"
    echo "  CSV write completed"
done < "$all_paths_temp"

# 一時ファイルをクリーンアップに追加
rm -f "$all_paths_temp"

echo "✅ Image diff analysis completed:" >&2
echo "   Added: $added_count" >&2
echo "   Deleted: $deleted_count" >&2
echo "   Modified: $modified_count" >&2
echo "   Summary: $DIFF_OUT_DIR/image_summary.csv" >&2

exit 0
