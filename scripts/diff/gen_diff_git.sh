#!/usr/bin/env bash
set -euo pipefail

# common.shがset -eを設定するので、このスクリプトでは無効化する
set +e

#
# 概要: 2つのリビジョン間のgitファイルの差分を生成する。
#       拡張子ごとにファイル出力する。
#
# 引数:
#   $1: BASEリビジョン (Git ref)
#   $2: CHANGEDリビジョン (Git ref)
#   $3: DIFF_OUT_DIR (成果物の出力先ディレクトリ)
#
# 依存設定 (config):
#   - GIT_DIFF_EXTENSIONS (配列)
#

# common.shとconfig読み込み
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../common.sh"
load_config

# === 引数チェック ===
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <BASE_REF> <CHANGED_REF> <DIFF_OUT_DIR>" >&2
    exit 1
fi

BASE_REF=$1
CHANGED_REF=$2
DIFF_OUT_DIR=$3

# 設定配列の安全な初期化
declare -a GIT_DIFF_EXTENSIONS_SAFE=()
if [[ -v GIT_DIFF_EXTENSIONS[@] ]]; then
    GIT_DIFF_EXTENSIONS_SAFE=("${GIT_DIFF_EXTENSIONS[@]}")
else
    echo "Warning: GIT_DIFF_EXTENSIONS not defined, using default extensions" >&2
    GIT_DIFF_EXTENSIONS_SAFE=(tex sty cls bib bst)
fi

echo "📄 Git diff generation started" >&2
echo "BASE_REF: $BASE_REF" >&2
echo "CHANGED_REF: $CHANGED_REF" >&2
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR" >&2
echo "Extensions: ${GIT_DIFF_EXTENSIONS_SAFE[*]}" >&2

# 出力ディレクトリの準備
mkdir -p "$DIFF_OUT_DIR/git-diffs"

# 一時ファイル
TEMP_CHANGED_FILES=$(mktemp)
TEMP_STATS=$(mktemp)

# クリーンアップ用のtrap設定
cleanup_temp_files() {
    rm -f "$TEMP_CHANGED_FILES" "$TEMP_STATS"
}
trap cleanup_temp_files EXIT

# === git diff の実行とファイル一覧取得 ===
echo "🔍 Analyzing git changes..." >&2

# 変更があったファイルの一覧を取得（A=追加, D=削除, M=変更, R=リネーム, C=コピー）
git diff --name-status "${BASE_REF}..${CHANGED_REF}" > "$TEMP_CHANGED_FILES"

if [ ! -s "$TEMP_CHANGED_FILES" ]; then
    echo "ℹ️ No changes found between $BASE_REF and $CHANGED_REF" >&2
    # 空のサマリーを作成
    echo "extension,added,removed,modified" > "$DIFF_OUT_DIR/git-summary.csv"
    for ext in "${GIT_DIFF_EXTENSIONS_SAFE[@]}"; do
        echo "$ext,0,0,0" >> "$DIFF_OUT_DIR/git-summary.csv"
    done
    echo "✅ Git diff analysis completed (no changes)" >&2
    exit 0
fi

echo "📊 Found $(wc -l < "$TEMP_CHANGED_FILES") changed files" >&2

# === 統計とサマリーCSVの初期化 ===
declare -A stats_added
declare -A stats_removed
declare -A stats_modified

# 全拡張子を0で初期化
for ext in "${GIT_DIFF_EXTENSIONS_SAFE[@]}"; do
    stats_added["$ext"]=0
    stats_removed["$ext"]=0
    stats_modified["$ext"]=0
done

# === 拡張子ごとの処理 ===
for ext in "${GIT_DIFF_EXTENSIONS_SAFE[@]}"; do
    echo "🔧 Processing .$ext files..." >&2

    # この拡張子のファイルのみを抽出
    ext_files=$(mktemp)
    while IFS=$'\t' read -r status file_path; do
        if [[ "$file_path" == *".$ext" ]]; then
            echo -e "$status\t$file_path" >> "$ext_files"

            # 統計カウント
            case "$status" in
                A*) stats_added["$ext"]=$((stats_added["$ext"] + 1)) ;;
                D*) stats_removed["$ext"]=$((stats_removed["$ext"] + 1)) ;;
                M*|R*|C*) stats_modified["$ext"]=$((stats_modified["$ext"] + 1)) ;;
            esac
        fi
    done < "$TEMP_CHANGED_FILES"

    # この拡張子のファイルがある場合のみ diff を生成
    if [ -s "$ext_files" ]; then
        echo "   Generating diff for .$ext ($(wc -l < "$ext_files") files)"

        # ファイルパスのみを抽出してgit diffを実行
        file_paths=$(cut -f2 "$ext_files" | tr '\n' ' ')

        # git diffを実行（エラーを無視して続行）
        if git diff "${BASE_REF}..${CHANGED_REF}" -- $file_paths > "$DIFF_OUT_DIR/git-diffs/$ext.diff" 2>/dev/null; then
            # 差分がある場合のサイズ確認
            if [ -s "$DIFF_OUT_DIR/git-diffs/$ext.diff" ]; then
                echo "   ✅ Generated $ext.diff ($(wc -l < "$DIFF_OUT_DIR/git-diffs/$ext.diff") lines)"
            else
                echo "   ℹ️ No content differences for .$ext files"
            fi
        else
            echo "   ⚠️ Git diff failed for .$ext files, creating empty diff"
            touch "$DIFF_OUT_DIR/git-diffs/$ext.diff"
        fi
    else
        echo "   ℹ️ No .$ext files changed"
        # 空のdiffファイルを作成
        touch "$DIFF_OUT_DIR/git-diffs/$ext.diff"
    fi

    rm -f "$ext_files"
done

# === サマリーCSVの作成 ===
echo "📝 Creating summary CSV..." >&2
echo "extension,added,removed,modified" > "$DIFF_OUT_DIR/git-summary.csv"

total_added=0
total_removed=0
total_modified=0

for ext in "${GIT_DIFF_EXTENSIONS_SAFE[@]}"; do
    added=${stats_added["$ext"]}
    removed=${stats_removed["$ext"]}
    modified=${stats_modified["$ext"]}

    echo "$ext,$added,$removed,$modified" >> "$DIFF_OUT_DIR/git-summary.csv"

    total_added=$((total_added + added))
    total_removed=$((total_removed + removed))
    total_modified=$((total_modified + modified))
done

echo "✅ Git diff analysis completed:"
echo "   Total added: $total_added"
echo "   Total removed: $total_removed"
echo "   Total modified: $total_modified"
echo "   Summary: $DIFF_OUT_DIR/git-summary.csv"
echo "   Diffs: $DIFF_OUT_DIR/git-diffs/"

exit 0
