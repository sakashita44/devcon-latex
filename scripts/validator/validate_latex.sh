#!/usr/bin/env bash
set -euo pipefail

SPEC_ARG="${1:-}"

echo "== LaTeX状態確認 =="

SPEC="${SPEC_ARG:-}"
if [ -z "$SPEC" ]; then
  if [ -f config ]; then
    SPEC="$(grep -E '^[[:space:]]*DEFAULT_TARGET[[:space:]]*=' config | head -n1 | cut -d= -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  fi
fi

if [ -z "$SPEC" ]; then
  echo "ERROR: TARGET が指定されていません。make validate-latex TARGET=path/to/main.tex または config に DEFAULT_TARGET を設定してください" >&2
  exit 1
fi

source ./scripts/common.sh

TARGET_ABS="$(resolve_path "$SPEC")" || { echo "ERROR: TARGET の解決に失敗しました: $SPEC" >&2; exit 1; }
check_file_exists "$TARGET_ABS"
echo "✓ Using TARGET=$TARGET_ABS"

if command -v latexmk >/dev/null 2>&1; then
  echo "✓ LaTeX環境: latexmk 利用可能"
else
  echo "✗ LaTeX環境: latexmk が見つかりません" >&2
  exit 1
fi

if [ "${ENABLE_LATEXINDENT:-true}" = "true" ] && command -v latexindent >/dev/null 2>&1; then
  echo "✓ コードフォーマット: latexindent 利用可能"
elif [ "${ENABLE_LATEXINDENT:-true}" = "true" ]; then
  echo "⚠ コードフォーマット: latexindent が見つかりません"
else
  echo "- コードフォーマット: 無効"
fi

tex_files=$(find . -name "*.tex" | wc -l)
echo "✓ TeXファイル数: $tex_files"

exit 0
