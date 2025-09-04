#!/usr/bin/env bash
set -euo pipefail

# scripts/build/build.sh
# usage: build.sh <mode> <target>
# mode: build | watch | clean

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/../common.sh"

# config読み込み
load_config

mode="${1:-build}"
TARGET_IN="${2:-}"

# fallback to DEFAULT_TARGET from config if TARGET not provided
if [ -z "$TARGET_IN" ]; then
    if [ -n "${DEFAULT_TARGET:-}" ]; then
        TARGET_IN="$DEFAULT_TARGET"
    else
        print_error "TARGET が指定されておらず、DEFAULT_TARGET も設定されていません";
        exit 1
    fi
fi

# configuration defaults (配列は既にload_configで初期化済み)
LATEXMKRC_EXPLORATION_RANGE="${LATEXMKRC_EXPLORATION_RANGE:-3}"
LOG_DIR="${LOG_DIR:-log}"
LOG_CAPTURE_DEFAULT="${LOG_CAPTURE_DEFAULT:-0}"
LOG_TIMESTAMP_FORMAT="${LOG_TIMESTAMP_FORMAT:-%Y%m%d-%H%M%S}"

# normalize and resolve target path
TARGET="$(resolve_path "$TARGET_IN")" || exit 1

if [ -d "$TARGET" ]; then
    print_error "エラー: TARGET はディレクトリです。ファイルパスを指定してください: $TARGET";
    exit 3
fi

check_file_exists "$TARGET"

TARGET_DIR="$(dirname "$TARGET")"

found_latexmkrc=""
if ! found_latexmkrc="$(find_up_file .latexmkrc "$TARGET_DIR" "$LATEXMKRC_EXPLORATION_RANGE" 2>/dev/null || true)"; then
        print_error ".latexmkrc が TARGET の同階層から上位 ${LATEXMKRC_EXPLORATION_RANGE} 階層で見つかりませんでした";
        # write minimal metadata for failed attempt
        mkdir -p "$LOG_DIR"
        norm_target="$(echo "$TARGET_IN" | sed 's#^\./##; s#/#_#g; s#[: ]#_#g')"
        mkdir -p "$LOG_DIR/$norm_target"
        ts="$(date +"$LOG_TIMESTAMP_FORMAT")"
        meta_file="$LOG_DIR/$norm_target/${ts}_$$.json"
        cat > "$meta_file" <<EOF
{
    "target": "${TARGET_IN}",
    "target_dir": "${TARGET_DIR}",
    "found_latexmkrc": null,
    "cmd": null,
    "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": 0,
    "exit_code": 2,
    "note": ".latexmkrc not found"
}
EOF
        exit 2
fi

# check latexmk installed
if ! command -v latexmk >/dev/null 2>&1; then
    print_error "エラー: latexmk が見つかりません。TeX Live 等をインストールしてください。";
    exit 4
fi

# prepare logging
norm_target="$(echo "$TARGET_IN" | sed 's#^\./##; s#/#_#g; s#[: ]#_#g')"
mkdir -p "$LOG_DIR/$norm_target"
ts="$(date +"$LOG_TIMESTAMP_FORMAT")"
meta_file="$LOG_DIR/$norm_target/${ts}_$$.json"

case "$mode" in
    build)
        extra=""
        ;;
    watch)
        extra="-pvc"
        ;;
    clean)
        extra="-C"
        ;;
    *)
        print_error "未知のモード: $mode";
        exit 5
        ;;
esac

target_base="$(basename "$TARGET")"
# prepare command string
# e.g. latexmk -cd /workspaces/src/main.tex -r /workspaces/src/.latexmkrc
cmd_str="latexmk -cd '$TARGET' -r '$found_latexmkrc' ${LATEXMK_OPTIONS[*]} $extra"

# run command and capture exit code; avoid set -e causing immediate exit
start_time_human="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
start_ts="$(date +%s)"
exit_code=0
if [ "${LOG_CAPTURE:-$LOG_CAPTURE_DEFAULT}" -eq 1 ]; then
    out_file="$LOG_DIR/$norm_target/${ts}_$$.out"
    err_file="$LOG_DIR/$norm_target/${ts}_$$.err"
    set +e
    eval "$cmd_str" >"$out_file" 2>"$err_file"
    exit_code=$?
    set -e
else
    set +e
    eval "$cmd_str"
    exit_code=$?
    set -e
fi

end_time_human="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
end_ts="$(date +%s)"
duration=$((end_ts - start_ts))

# write metadata
cat > "$meta_file" <<EOF
{
  "target": "${TARGET_IN}",
  "target_dir": "${TARGET_DIR}",
  "found_latexmkrc": "${found_latexmkrc}",
  "cmd": "${cmd_str}",
  "start_time": "${start_time_human}",
  "end_time": "${end_time_human}",
  "duration_seconds": ${duration},
  "exit_code": ${exit_code},
  "note": ""
}
EOF

if [ $exit_code -ne 0 ]; then
    print_error "latexmk が exit code=${exit_code} で終了しました。詳細は ${meta_file} を参照してください。"
fi

exit $exit_code
