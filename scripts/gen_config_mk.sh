#!/usr/bin/env bash
set -euo pipefail

# gen_config_mk.sh
# Usage: ./scripts/gen_config_mk.sh <config_path> <out_path>
# Reads keys from the config file using common.sh config loading
# and writes a Makefile fragment to <out_path>.

if [ $# -ne 2 ]; then
  echo "Usage: $0 <config_path> <out_path>" >&2
  exit 2
fi

CONFIG_PATH="$1"
OUT_PATH="$2"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "config file '$CONFIG_PATH' not found" >&2
  exit 3
fi

# Source common utilities and load config
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
load_config_from_path "$CONFIG_PATH"

# Keys to extract (based on config.example)
SCALAR_KEYS=(
  DEFAULT_TARGET
  DEFAULT_OUT_DIR
  LATEXMKRC_EXPLORATION_RANGE
  DVC_REMOTE_NAME
  DVC_REMOTE_URL
  LOG_DIR
  LOG_CAPTURE_DEFAULT
  LOG_TIMESTAMP_FORMAT
)

# Array keys (will be converted to space-separated strings for Make)
ARRAY_KEYS=(
  LATEXMK_OPTIONS
  LATEXPAND_OPTIONS
  LATEXDIFF_OPTIONS
  IMAGE_EXTENSIONS
  IMAGE_DIFF_EXTENSIONS
  GIT_DIFF_EXTENSIONS
  DVC_MANAGED_DIRS
)

# Temporary output
tmpfile=$(mktemp)
written=0

escape_for_make() {
  # Escape $ as $$ for Make; preserve other characters
  local v="$1"
  v="${v//\$/\$\$}"
  printf '%s' "$v"
}

# Process scalar keys
for k in "${SCALAR_KEYS[@]}"; do
  if declare -p "$k" >/dev/null 2>&1; then
    eval "val=\$$k"
    if [ -n "$val" ]; then
      esc=$(escape_for_make "$val")
      printf '%s := %s\n' "$k" "$esc" >> "$tmpfile"
      written=$((written+1))
    fi
  fi
done

# Process array keys (convert to space-separated strings)
for k in "${ARRAY_KEYS[@]}"; do
  if declare -p "$k" >/dev/null 2>&1; then
    eval "declare -n arr_ref=$k"
    if [ ${#arr_ref[@]} -gt 0 ]; then
      # Join array elements with spaces
      val=$(printf '%s ' "${arr_ref[@]}")
      val="${val% }" # Remove trailing space
      esc=$(escape_for_make "$val")
      printf '%s := %s\n' "$k" "$esc" >> "$tmpfile"
      written=$((written+1))
    fi
  fi
done

if [ $written -eq 0 ]; then
  echo "Error: no configuration keys found in $CONFIG_PATH" >&2
  rm -f "$tmpfile"
  exit 5
fi

mv "$tmpfile" "$OUT_PATH"
chmod 644 "$OUT_PATH"

exit 0
