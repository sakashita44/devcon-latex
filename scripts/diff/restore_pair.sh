#!/usr/bin/env bash
set -euo pipefail

#
# 概要: restore.sh を2回呼び出し、BASEとCHANGEDの両リビジョンを復元するラッパースクリプト。
#
# 引数:
#   $1: BASE (git ref)
#   $2: CHANGED (git ref)
#   $3: TMP_DIR (復元の親となる一時ディレクトリ)
#
# 出力:
#   標準出力:
#     1行目: BASEリビジョンを復元したワークツリーの絶対パス
#     2行目: CHANGEDリビジョンを復元したワークツリーの絶対パス
#   標準エラー: エラーメッセージ
#
# 終了コード:
#   0: 成功
#   非0: 失敗
#

# === 引数のチェック ===
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <BASE_REF> <CHANGED_REF> <TMP_DIR>" >&2
    exit 1
fi

BASE_REF=$1
CHANGED_REF=$2
TMP_DIR=$3

# === スクリプトディレクトリの特定 ===
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
RESTORE_SCRIPT="$SCRIPT_DIR/restore.sh"

# === restore.sh の存在確認 ===
if [ ! -f "$RESTORE_SCRIPT" ]; then
    echo "Error: restore.sh not found at $RESTORE_SCRIPT" >&2
    exit 1
fi

# === TMP_DIR の作成 ===
mkdir -p "$TMP_DIR"

# === BASE リビジョンの復元 ===
BASE_DEST_DIR="$TMP_DIR/base"
BASE_REPO_PATH=$(bash "$RESTORE_SCRIPT" "$BASE_REF" "$BASE_DEST_DIR" 2>&1 | tail -n1)
if [ $? -ne 0 ] || [ -z "$BASE_REPO_PATH" ]; then
    echo "Error: Failed to restore BASE revision $BASE_REF" >&2
    exit 1
fi

# === CHANGED リビジョンの復元 ===
CHANGED_DEST_DIR="$TMP_DIR/changed"
CHANGED_REPO_PATH=$(bash "$RESTORE_SCRIPT" "$CHANGED_REF" "$CHANGED_DEST_DIR" 2>&1 | tail -n1)
if [ $? -ne 0 ] || [ -z "$CHANGED_REPO_PATH" ]; then
    echo "Error: Failed to restore CHANGED revision $CHANGED_REF" >&2
    exit 1
fi

# === 復元パスの出力 ===
echo "$BASE_REPO_PATH"
echo "$CHANGED_REPO_PATH"
