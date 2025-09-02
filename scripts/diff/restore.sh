#!/usr/bin/env bash
set -euo pipefail

#
# 概要: 指定された単一のGitリビジョンを、指定されたディレクトリにワークツリーとして復元する。
#       DVCやGit LFSで管理されているファイルも復元する。
#
# 引数:
#   $1: GIT_REF (復元するGitリビジョン)
#   $2: DEST_DIR (復元先のディレクトリパス)
#
# 出力:
#   標準出力:
#     復元先ディレクトリの絶対パス
#   標準エラー: エラーメッセージ
#
# 終了コード:
#   0: 成功
#   非0: 失敗
#

# === Main Script ===
# スクリプトのルートディレクトリを特定
# SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# source "$SCRIPT_DIR/../common.sh"

# === 引数のチェック ===
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <GIT_REF> <DEST_DIR>" >&2
    exit 1
fi

GIT_REF=$1
DEST_DIR=$2

# === ワークツリーの作成 ===
# worktree作成前に、もし古いものが残っていたら削除する
git worktree remove -f "$DEST_DIR" 2>/dev/null || true

# worktreeを作成
git worktree add "$DEST_DIR" "$GIT_REF" >&2

# === DVC/Git LFS ファイルの復元 ===
if [ -d "$DEST_DIR/.dvc" ]; then
    (cd "$DEST_DIR" && dvc pull -f)
fi
# git lfs statusの終了コードは、LFSがなくても0なので、`git lfs`コマンド自体の存在をチェック
if git lfs >/dev/null 2>&1; then
    (cd "$DEST_DIR" && git lfs pull)
fi

# === 復元パスの出力 ===
# readlink -f で絶対パスに変換して出力
echo "$(readlink -f "$DEST_DIR")"
