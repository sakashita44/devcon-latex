#!/usr/bin/env bash
set -euo pipefail

#
# 概要: 差分生成ワークフローのオーケストレーター
#       指定された2つのGitリビジョン間の文書差分、画像差分、Git差分を自動生成する
#
# 引数:
#   $1 TARGET_BASE (BASE側で使うエントリ .tex のリポジトリ相対パス)
#   $2 TARGET_CHANGED (CHANGED側で使うエントリ .tex のリポジトリ相対パス)
#   $3 BASE (git ref)
#   $4 CHANGED (git ref)
#   $5 OUT (出力ディレクトリ、省略可、デフォルト=DEFAULT_OUT_DIR)
#

# === 1. 前置チェック ===
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../" && pwd)

# common.shとconfig読み込み
source "$SCRIPT_DIR/../common.sh"
load_config

# === ユーティリティ関数 ===
update_metadata_phase() {
    local phase=$1
    local status=$2
    local timestamp=$3
    local error_message=${4:-}

    echo "Updating metadata: $phase -> $status at $timestamp" >&2
    if [ -n "$error_message" ]; then
        echo "  Error: $error_message" >&2
    fi

    # JSONファイル更新
    if [ -f "$DIFF_OUT_DIR/metadata.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            # jqを使用してJSONを更新
            local temp_file=$(mktemp)
            if [ -n "$error_message" ]; then
                jq --arg phase "$phase" --arg status "$status" --arg timestamp "$timestamp" --arg error "$error_message" \
                   '.phases[$phase] = {"status": $status, "timestamp": $timestamp, "error": $error}' \
                   "$DIFF_OUT_DIR/metadata.json" > "$temp_file" && mv "$temp_file" "$DIFF_OUT_DIR/metadata.json"
            else
                jq --arg phase "$phase" --arg status "$status" --arg timestamp "$timestamp" \
                   '.phases[$phase] = {"status": $status, "timestamp": $timestamp}' \
                   "$DIFF_OUT_DIR/metadata.json" > "$temp_file" && mv "$temp_file" "$DIFF_OUT_DIR/metadata.json"
            fi
        fi
    fi
}

update_metadata_status() {
    local status=$1
    echo "Updating overall status: $status" >&2

    # JSONファイル更新
    if [ -f "$DIFF_OUT_DIR/metadata.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            local temp_file=$(mktemp)
            jq --arg status "$status" '.status = $status' \
               "$DIFF_OUT_DIR/metadata.json" > "$temp_file" && mv "$temp_file" "$DIFF_OUT_DIR/metadata.json"
        fi
    fi
}

# 必須ツールの存在チェック
check_required_tools() {
    local tools=("git" "latexmk" "latexdiff" "latexpand" "grep" "awk" "sed" "find" "sort" "xargs")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    # sha1sum または openssl の確認
    if ! command -v "sha1sum" >/dev/null 2>&1 && ! command -v "openssl" >/dev/null 2>&1; then
        missing_tools+=("sha1sum or openssl")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "Error: Missing required tools: ${missing_tools[*]}" >&2
        exit 3
    fi
}

check_required_tools

# === 2. 引数受け取りと解決 ===
TARGET_BASE_ARG=${1:-}
TARGET_CHANGED_ARG=${2:-}
BASE_ARG=${3:-}
CHANGED_ARG=${4:-}
OUT_ARG=${5:-}

# 引数チェック
if [ -z "$TARGET_BASE_ARG" ] || [ -z "$TARGET_CHANGED_ARG" ] || [ -z "$BASE_ARG" ] || [ -z "$CHANGED_ARG" ]; then
    echo "Error: TARGET_BASE, TARGET_CHANGED, BASE, and CHANGED arguments are required" >&2
    echo "Usage: $0 <TARGET_BASE> <TARGET_CHANGED> <BASE> <CHANGED> [OUT]" >&2
    exit 2
fi

# ローカル変数に代入
TARGET_BASE=$TARGET_BASE_ARG
TARGET_CHANGED=$TARGET_CHANGED_ARG
OUT=${OUT_ARG:-${DEFAULT_OUT_DIR}}

# resolve_refs.sh で BASE/CHANGED を検証・解決
RESOLVED_REFS=$(bash "$SCRIPT_DIR/resolve_refs.sh" "$BASE_ARG" "$CHANGED_ARG")
BASE=$(echo "$RESOLVED_REFS" | cut -d' ' -f1)
CHANGED=$(echo "$RESOLVED_REFS" | cut -d' ' -f2)

# OUT を resolve_path で絶対化
OUT_ABS=$(resolve_path "$OUT")

# === 3. DIFF_OUT_DIR の組み立て ===
DIFF_OUT_DIR="${OUT_ABS%/}/diff_${BASE}_to_${CHANGED}/"

# 既存ディレクトリの削除（安全確認後）
if [ -d "$DIFF_OUT_DIR" ]; then
    # 安全確認: 空や"/"は禁止
    if [ "$DIFF_OUT_DIR" = "/" ] || [ -z "$DIFF_OUT_DIR" ]; then
        echo "Error: Invalid DIFF_OUT_DIR: $DIFF_OUT_DIR" >&2
        exit 1
    fi
    rm -rf "$DIFF_OUT_DIR"
fi

mkdir -p "$DIFF_OUT_DIR"

# === 4. ロックの確立 ===
LOCKDIR="$DIFF_OUT_DIR/.lockdir"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    echo "Error: Failed to acquire lock (concurrent run?)" >&2
    exit 4
fi

# trap で終了時にロック解除・TMP削除を保証
cleanup() {
    local exit_code=$?
    if [ -d "$LOCKDIR" ]; then
        rmdir "$LOCKDIR" 2>/dev/null || true
    fi
    # 正常終了時のTMP_DIR削除（設定のKEEP_TMP_DIRまたは環境変数でスキップ可能）
    if [ $exit_code -eq 0 ] && [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
        local keep_tmp="${KEEP_TMP_DIR:-0}"  # 設定ファイルから取得、未設定時は0
        keep_tmp="${KEEP_TMP_DIR_ENV:-$keep_tmp}"  # 環境変数で上書き可能
        if [ "$keep_tmp" != "1" ]; then
            rm -rf "$TMP_DIR"
        else
            echo "TMP_DIR preserved for debugging: $TMP_DIR" >&2
        fi
    fi
}
trap cleanup EXIT

# === 5. TMP_DIR 作成 ===
TMP_DIR="$DIFF_OUT_DIR/tmp/"
mkdir -p "$TMP_DIR"

# === 6. metadata.json, logs 初期化 ===
mkdir -p "$DIFF_OUT_DIR/logs"

# metadata.json の初期化
cat > "$DIFF_OUT_DIR/metadata.json" <<EOF
{
  "created_at": "$(date -Iseconds)",
  "base": "$BASE",
  "changed": "$CHANGED",
  "target_base": "$TARGET_BASE",
  "target_changed": "$TARGET_CHANGED",
  "out_dir": "$OUT_ABS",
  "tmp_dir": "$TMP_DIR",
  "status": "running",
  "phases": {
    "restore": {"status": "pending"},
    "pdf": {"status": "pending"},
    "images": {"status": "pending"},
    "git": {"status": "pending"}
  },
  "notes": [],
  "tools": {
    "git": true,
    "latexmk": true,
    "latexdiff": true,
    "latexpand": true,
    "sha1sum": $(command -v "sha1sum" >/dev/null 2>&1 && echo true || echo false),
    "openssl": $(command -v "openssl" >/dev/null 2>&1 && echo true || echo false),
    "dvc": $(command -v "dvc" >/dev/null 2>&1 && echo true || echo false),
    "git_lfs": $(command -v "git" >/dev/null 2>&1 && git lfs version >/dev/null 2>&1 && echo true || echo false)
  }
}
EOF

# === 7. リビジョン復元 ===
echo "=== Restoring revisions ==="
update_metadata_phase "restore" "running" "$(date -Iseconds)"

if ! RESTORE_OUTPUT=$(bash "$SCRIPT_DIR/restore_pair.sh" "$BASE" "$CHANGED" "$TMP_DIR" 2>"$DIFF_OUT_DIR/logs/restore.log"); then
    update_metadata_phase "restore" "fail" "" "restore failed"
    update_metadata_status "error"
    exit 5
fi

BASE_REPO_PATH=$(echo "$RESTORE_OUTPUT" | head -n1)
CHANGED_REPO_PATH=$(echo "$RESTORE_OUTPUT" | tail -n1)

update_metadata_phase "restore" "ok" "$(date -Iseconds)"

# === 8. TARGET系の存在検証（即時） ===
echo "=== Verifying target files ==="
if [ ! -f "$BASE_REPO_PATH/$TARGET_BASE" ] || [ ! -f "$CHANGED_REPO_PATH/$TARGET_CHANGED" ]; then
    update_metadata_phase "pdf" "fail" "" "target-not-found"
    update_metadata_status "error"
    exit 2
fi

# === 9. 差分フェーズの逐次実行 ===
OVERALL_STATUS="ok"

# 画像差分（PDF生成前に実行）
echo "=== Generating image diff ==="
update_metadata_phase "images" "running" "$(date -Iseconds)"
if bash "$SCRIPT_DIR/gen_diff_images.sh" "$TARGET_BASE" "$TARGET_CHANGED" "$BASE_REPO_PATH" "$CHANGED_REPO_PATH" "$DIFF_OUT_DIR" 2>"$DIFF_OUT_DIR/logs/images.log"; then
    update_metadata_phase "images" "ok" "$(date -Iseconds)"
else
    update_metadata_phase "images" "fail" "$(date -Iseconds)" "image diff failed"
    OVERALL_STATUS="partial-fail"
fi

# Git差分
echo "=== Generating git diff ==="
update_metadata_phase "git" "running" "$(date -Iseconds)"
if bash "$SCRIPT_DIR/gen_diff_git.sh" "$BASE" "$CHANGED" "$DIFF_OUT_DIR" 2>"$DIFF_OUT_DIR/logs/git.log"; then
    update_metadata_phase "git" "ok" "$(date -Iseconds)"
else
    update_metadata_phase "git" "fail" "$(date -Iseconds)" "git diff failed"
    OVERALL_STATUS="partial-fail"
fi

# PDF差分（最後に実行）
echo "=== Generating PDF diff ==="
update_metadata_phase "pdf" "running" "$(date -Iseconds)"
if bash "$SCRIPT_DIR/gen_diff_pdf.sh" "$TARGET_BASE" "$TARGET_CHANGED" "$BASE_REPO_PATH" "$CHANGED_REPO_PATH" "$DIFF_OUT_DIR" 2>"$DIFF_OUT_DIR/logs/pdf.log"; then
    update_metadata_phase "pdf" "ok" "$(date -Iseconds)"
else
    update_metadata_phase "pdf" "fail" "$(date -Iseconds)" "pdf generation failed"
    OVERALL_STATUS="partial-fail"
fi

# === 10. 収束処理 ===
update_metadata_status "$OVERALL_STATUS"

echo "=== Diff generation completed ==="
echo "Status: $OVERALL_STATUS"
echo "Output directory: $DIFF_OUT_DIR"

exit 0
