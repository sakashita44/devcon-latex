#!/usr/bin/env bash
set -euo pipefail

SPEC_ARG="${1:-}"

echo "== LaTeX状態確認 =="

source ./scripts/common.sh

SPEC="${SPEC_ARG:-}"
if [ -z "$SPEC" ]; then
  if [ -f config ]; then
    SPEC="$(get_config_value DEFAULT_TARGET config)"
  fi
fi

if [ -z "$SPEC" ]; then
  echo "ERROR: TARGET が指定されていません。make validate-latex TARGET=path/to/main.tex または config に DEFAULT_TARGET を設定してください" >&2
  exit 1
fi

TARGET_ABS="$(resolve_path "$SPEC")" || { echo "ERROR: TARGET の解決に失敗しました: $SPEC" >&2; exit 1; }
check_file_exists "$TARGET_ABS"
echo "✓ Using TARGET=$TARGET_ABS"

if command -v latexmk >/dev/null 2>&1; then
  echo "✓ LaTeX環境: latexmk 利用可能"
else
  echo "✗ LaTeX環境: latexmk が見つかりません" >&2
  exit 1
fi

formats_found=0
if command -v latexformat >/dev/null 2>&1; then
  echo "✓ コードフォーマット: latexformat 利用可能"
  formats_found=1
fi
if command -v latexindent >/dev/null 2>&1; then
  echo "✓ コードフォーマット: latexindent 利用可能"
  formats_found=1
fi
if [ $formats_found -eq 0 ]; then
  echo "⚠ コードフォーマット: latexformat / latexindent 共に見つかりません"
fi

tex_files=$(find . -name "*.tex" | wc -l)
echo "✓ TeXファイル数: $tex_files"

exit 0
