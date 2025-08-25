#!/usr/bin/env bash
# scripts/diff/main.sh
# 空の差分メインスクリプト (issue8 Phase 3 のプレースホルダ)
# 引数:
#   $1 - TARGET (tex file path). デフォルトは config の DEFAULT_TARGET
#   $2 - BASE (git ref). デフォルトは直近の tag
#   $3 - CHANGED (git ref). デフォルトは 1つ前の tag
#   $4 - OUT (出力ディレクトリ). デフォルトは config の DEFAULT_OUT_DIR

set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../" && pwd)

TARGET_ARG=${1:-}
BASE_ARG=${2:-}
CHANGED_ARG=${3:-}
OUT_ARG=${4:-}

# load config if exists (parse KEY=VALUE to allow unquoted space-separated lists)
if [ -f "$REPO_ROOT/config" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # skip comments and empty lines
        case "$line" in
            ''|\#*) continue ;;
        esac
        if echo "$line" | grep -q '=' >/dev/null 2>&1; then
            key=${line%%=*}
            value=${line#*=}
            # trim possible leading/trailing spaces
            key=$(echo "$key" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$$//')
            value=$(echo "$value" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$$//')
            export "$key"="$value"
        fi
    done < "$REPO_ROOT/config"
fi

# Resolve defaults
if [ -z "$TARGET_ARG" ]; then
    TARGET_ARG=${DEFAULT_TARGET:-src/main.tex}
fi

if [ -z "$OUT_ARG" ]; then
    OUT_ARG=${DEFAULT_OUT_DIR:-build/}
fi

# Determine git tags (most recent first)
get_latest_tags() {
    # list tags sorted by version/rev-date; fallback to HEAD if no tags
    if git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/tags" >/dev/null 2>&1; then
        tags=($(git -C "$REPO_ROOT" for-each-ref --sort=-creatordate --format '%(refname:strip=2)' refs/tags))
    else
        tags=()
    fi

    echo "${tags[@]:-}"
}

if [ -z "$BASE_ARG" ] || [ -z "$CHANGED_ARG" ]; then
    tags_str=$(get_latest_tags)
    # convert to array
    IFS=$'\n' read -r -a tags_arr <<<"$tags_str"
    if [ ${#tags_arr[@]} -ge 2 ]; then
        # latest = tags_arr[0], previous = tags_arr[1]
        :
    fi
    if [ -z "$BASE_ARG" ]; then
        if [ ${#tags_arr[@]} -ge 1 ]; then
            BASE_ARG=${tags_arr[1]:-}
        else
            BASE_ARG="HEAD~1"
        fi
    fi
    if [ -z "$CHANGED_ARG" ]; then
        if [ ${#tags_arr[@]} -ge 1 ]; then
            CHANGED_ARG=${tags_arr[0]:-}
        else
            CHANGED_ARG="HEAD"
        fi
    fi
fi

# Print resolved values and exit (placeholder)
cat <<EOF
[diff main placeholder]
TARGET: $TARGET_ARG
BASE:   $BASE_ARG
CHANGED:$CHANGED_ARG
OUT:    $OUT_ARG
Repository root: $REPO_ROOT
EOF

# TODO: 実実装はここに追加

exit 0
