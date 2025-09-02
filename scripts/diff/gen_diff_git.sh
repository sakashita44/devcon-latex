#!/usr/bin/env bash
set -euo pipefail

#
# 概要: 2つのリビジョン間のgit diffを指定された拡張子でフィルタリングし、
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

echo "Git diff generation (placeholder)"
echo "BASE_REF: $BASE_REF"
echo "CHANGED_REF: $CHANGED_REF"
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR"

# プレースホルダー: ディレクトリ作成
mkdir -p "$DIFF_OUT_DIR/git-diffs"

# プレースホルダー: CSVファイル作成
echo "extension,added,removed,modified" > "$DIFF_OUT_DIR/git-summary.csv"

echo "Git diff generation completed (placeholder)"
exit 0

# === 初期設定 ===
# TODO: common.shとconfigを読み込む
# TODO: configで定義された配列変数が未定義の場合に備え、空配列で初期化する

# === git diff の実行とフィルタリング ===
# TODO: git diff --name-status を実行し、変更があったファイルの一覧を取得する
# TODO: GIT_DIFF_EXTENSIONS に含まれる拡張子のファイルのみを抽出する

# === 拡張子ごとの差分ファイル作成 ===
# TODO: 抽出したファイルごとに git diff を実行し、
#       $3/git-diffs/<ext>.diff という形式で保存する

# === サマリーCSVの作成 ===
# TODO: $3/git-summary.csv を作成する
#       (カラム: extension, added, removed, modified)

# === 結果の報告 ===
# TODO: 成功または失敗を標準出力に報告する
