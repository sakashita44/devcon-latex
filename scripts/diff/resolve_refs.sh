#!/usr/bin/env bash
set -euo pipefail

# scripts/diff/resolve_refs.sh
#
# 引数:
#   $1 - BASE (may be empty)
#   $2 - CHANGED (may be empty)
# 出力:
#   prints "<BASE> <CHANGED>" to stdout (space separated)
# 動作:
#   - 引数が両方未指定の場合は、リポジトリに2つ以上のタグが必要。最新2つを返す。なければ exit 2
#   - 引数が1つだけ与えられた場合はエラーで exit 2
#   - 引数が両方与えられた場合はそれらが存在するか検証し、存在しなければ exit 2
#
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Git リポジトリルートを動的に検出
find_git_root() {
    local current_dir="${1:-$(pwd)}"
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    return 1
}

REPO_ROOT=$(find_git_root) || { echo "ERROR: not in git repository" >&2; exit 1; }

BASE_ARG=${1:-}
CHANGED_ARG=${2:-}

# If exactly one of BASE/CHANGED is provided, fail early per requirement
if { [ -n "$BASE_ARG" ] && [ -z "$CHANGED_ARG" ]; } || { [ -z "$BASE_ARG" ] && [ -n "$CHANGED_ARG" ]; }; then
    echo "ERROR: please provide both BASE and CHANGED, or neither (to auto-resolve latest two tags)." >&2
    exit 2
fi

# Verify that a given git ref exists (commit-ish, tag, branch, HEAD, etc.)
verify_ref() {
    local ref="$1"
    # git rev-parse accepts commit-ish (short/long hashes, HEAD, branches, tags)
    if git -C "$REPO_ROOT" rev-parse --verify --quiet "$ref" >/dev/null 2>&1; then
        return 0
    fi
    # Fallback: check for tag name explicitly
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/tags/$ref" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Collect tags newest-first into an array (quietly return nothing if no tags)
collect_tags() {
    git -C "$REPO_ROOT" for-each-ref --sort=-creatordate --format='%(refname:strip=2)' refs/tags 2>/dev/null || true
}

mapfile -t tags < <(collect_tags)

# If neither provided, require at least two tags and return them (CHANGED newest, BASE previous)
if [ -z "$BASE_ARG" ] && [ -z "$CHANGED_ARG" ]; then
    if [ ${#tags[@]} -ge 2 ]; then
        CHANGED_ARG=${tags[0]}
        BASE_ARG=${tags[1]}
        printf '%s %s' "$BASE_ARG" "$CHANGED_ARG"
        exit 0
    else
        echo "ERROR: repository does not contain two tags. Please create tags or pass BASE and CHANGED explicitly." >&2
        exit 2
    fi
fi

# If both provided, verify existence and echo
if [ -n "$BASE_ARG" ] && [ -n "$CHANGED_ARG" ]; then
    if ! verify_ref "$BASE_ARG"; then
        echo "ERROR: ref '$BASE_ARG' not found in repository" >&2
        exit 2
    fi
    if ! verify_ref "$CHANGED_ARG"; then
        echo "ERROR: ref '$CHANGED_ARG' not found in repository" >&2
        exit 2
    fi
    printf '%s %s' "$BASE_ARG" "$CHANGED_ARG"
    exit 0
fi

echo "ERROR: unexpected state in resolve_refs.sh" >&2
exit 2
printf '%s %s' "$BASE_ARG" "$CHANGED_ARG"
