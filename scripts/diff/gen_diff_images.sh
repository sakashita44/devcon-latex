#!/usr/bin/env bash
set -euo pipefail

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

echo "Image diff generation (placeholder)"
echo "TARGET_BASE: $TARGET_BASE"
echo "TARGET_CHANGED: $TARGET_CHANGED"
echo "BASE_REPO_PATH: $BASE_REPO_PATH"
echo "CHANGED_REPO_PATH: $CHANGED_REPO_PATH"
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR"

# プレースホルダー: ディレクトリ作成
mkdir -p "$DIFF_OUT_DIR/images"/{added,deleted,modified}

# プレースホルダー: CSVファイル作成
echo "path,status,refs,notes" > "$DIFF_OUT_DIR/image_summary.csv"

echo "Image diff generation completed (placeholder)"
exit 0

# === 初期設定 ===
# TODO: common.shとconfigを読み込む
# TODO: configで定義された配列変数が未定義の場合に備え、空配列で初期化する

# === 画像ファイルの一覧取得 ===
# TODO: BASE側とCHANGED側から、IMAGE_DIFF_EXTENSIONSで指定された拡張子の画像ファイルを検索する

# === ファイルのハッシュ値計算 ===
# TODO: 検索した全画像ファイルのSHA-1ハッシュを計算する

# === 差分の判定 (追加/削除/変更) ===
# TODO: ファイルパスとハッシュ値を比較し、各画像を added, deleted, modified に分類する

# === 差分画像の出力 ===
# TODO: 分類結果に基づき、画像を $5/images/{added,deleted,modified}/ にコピーする
# TODO: ファイル名の衝突を避けるため、サニタイズやハッシュ値の付与を行う

# === サマリーCSVの作成 ===
# TODO: $5/image_summary.csv を作成する
#       (カラム: path, status, refs, notes)

# === 結果の報告 ===
# TODO: 成功または失敗を標準出力に報告する
