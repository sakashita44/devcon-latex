#!/usr/bin/env bash
set -euo pipefail

source ./scripts/common.sh

if [ -n "${1:-}" ]; then
  TAG="${1}";
  echo "== タグ重複確認 =="
  if git tag | grep -q "^${TAG}$"; then
    echo "✗ タグ ${TAG} は既に存在します"
    git tag | grep "${TAG}" | sed 's/^/  /'
    exit 1
  else
    echo "✓ タグ ${TAG} は利用可能です"
  fi
else
  echo "== タグ確認 =="
  tag_count=$(git tag | wc -l)
  echo "現在のタグ数: $tag_count"
  if [ $tag_count -gt 0 ]; then
    echo "最新のタグ:"
    git tag | tail -5 | sed 's/^/  /'
  fi
fi
