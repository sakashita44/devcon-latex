#!/usr/bin/env bash
set -euo pipefail

# gen_config_mk.sh
# Usage: ./scripts/gen_config_mk.sh <config_path> <out_path>
# Reads keys from the config file using scripts/common.sh::get_config_value
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

# Source common utilities to use get_config_value
# common.sh may print errors; allow it
source ./scripts/common.sh

# Keys to extract (based on config.example)
KEYS=(
  DEFAULT_TARGET
  DEFAULT_OUT_DIR
  LATEXMK_OPTIONS
  LATEXMKRC_EXPLORATION_RANGE
  IMAGE_EXTENSIONS
  IMAGE_DIFF_EXTENSIONS
  GIT_DIFF_EXTENSIONS
  DVC_MANAGED_DIRS
  DVC_REMOTE_NAME
  DVC_REMOTE_URL
  LOG_DIR
  LOG_CAPTURE_DEFAULT
  LOG_TIMESTAMP_FORMAT
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

for k in "${KEYS[@]}"; do
  val=$(get_config_value "$k" "$CONFIG_PATH") || true
  if [ -n "$val" ]; then
    # trim (leading/trailing spaces)
    val_trimmed=$(printf '%s' "$val" | sed -e 's/^ *//' -e 's/ *$//')
    # fail if contains newline (use bash-safe check)
    if [[ "$val_trimmed" == *$'\n'* ]]; then
      echo "Error: config value for $k contains newline; unsupported" >&2
      rm -f "$tmpfile"
      exit 4
    fi
    esc=$(escape_for_make "$val_trimmed")
    printf '%s := %s\n' "$k" "$esc" >> "$tmpfile"
    written=$((written+1))
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
