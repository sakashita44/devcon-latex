#!/usr/bin/env bash
set -euo pipefail

source ./scripts/common.sh

echo "== Git状態確認 =="
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "✓ Gitリポジトリ: 初期化済み"
  uncommitted=$(git status --porcelain | wc -l)
  if [ "$uncommitted" -eq 0 ]; then
    echo "✓ 作業ディレクトリ: クリーン"
  else
    echo "⚠ 作業ディレクトリ: $uncommitted 個の未コミット変更"
    git status --short | head -5 | sed 's/^/    /'
  fi
  current_branch=$(git branch --show-current)
  echo "✓ 現在のブランチ: $current_branch"
  tag_count=$(git tag | wc -l)
  echo "✓ タグ数: $tag_count"
else
  echo "✗ Gitリポジトリが初期化されていません"
  exit 1
fi
