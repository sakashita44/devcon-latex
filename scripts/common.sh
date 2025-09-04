#!/bin/bash
# DVC共通関数とユーティリティ

set -e

# 色付きメッセージ
print_info() {
    echo "ℹ️  $1"
}

print_success() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1" >&2
}

# DVC初期化チェック
check_dvc_initialized() {
    if [ ! -d ".dvc" ]; then
        print_error "DVCが初期化されていません"
        print_info "まず 'make dvc-init' を実行してください"
        exit 1
    fi
}

# ファイル存在チェック
check_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        print_error "ファイル $file が見つかりません"
        exit 1
    fi
}

# パス解決: 相対パスを絶対化し、環境変数とチルダを展開して返す
# 引数: パス文字列
# 出力: 絶対パスを標準出力へ
# 返り値: 0 成功, 非ゼロ 失敗
resolve_path() {
    local p="$1"
    if [ -z "$p" ]; then
        print_error "resolve_path: 引数が空です"
        return 1
    fi
    # 環境変数とチルダ展開 (eval を限定的に使用)
    # 注意: 設定ファイル由来の値を安全に扱う前提
    eval "p=\"$p\""

    # readlink -f で正規化できれば使う
    if command -v readlink >/dev/null 2>&1; then
        readlink -f -- "$p" || return 1
        return $?
    fi

    # realpath を試す
    if command -v realpath >/dev/null 2>&1; then
        realpath "$p" || return 1
        return $?
    fi

    # 最低限の相対→絶対変換
    if [ "${p#/}" = "$p" ]; then
        printf '%s\n' "$(pwd)/$p"
    else
        printf '%s\n' "$p"
    fi
}

# find_up_file: 指定開始パスから上方向へファイルを探索するユーティリティ
# 引数: (filename, start_path, max_levels)
# 出力: 見つかったファイルの絶対パスを標準出力へ（見つからなければ何も出力せず非ゼロ終了）
find_up_file() {
    local filename="$1"
    local start_path="$2"
    local max_levels="${3:-3}"

    if [ -z "$filename" ] || [ -z "$start_path" ]; then
        print_error "find_up_file: 引数が不正です。usage: find_up_file <filename> <start_path> [max_levels]"
        return 2
    fi

    local cur_dir
    cur_dir="$(resolve_path "$start_path")" || return 3
    local i=0
    while [ $i -le "$max_levels" ]; do
        if [ -f "$cur_dir/$filename" ]; then
            resolve_path "$cur_dir/$filename"
            return 0
        fi
        if [ "$cur_dir" = "/" ] || [ "$cur_dir" = "" ]; then
            break
        fi
        cur_dir="$(dirname "$cur_dir")"
        i=$((i + 1))
    done
    return 1
}

# get_config_value: 指定されたコンフィグファイル（パス）からキーの値を安全に取得する
# 引数: (key, config_path)
# 出力: 値を標準出力へ（見つからなければ空）
get_config_value() {
    local key="$1"
    local cfg_path="$2"
    if [ -z "$key" ] || [ -z "$cfg_path" ]; then
        print_error "get_config_value: usage: get_config_value <KEY> <CONFIG_PATH>"
        return 2
    fi
    if [ ! -f "$cfg_path" ]; then
        return 0
    fi
    # match lines like KEY=... (first occurrence)
    local line
    line=$(grep -E "^${key}=" "$cfg_path" | sed -n "s/^${key}=//p" | sed 's/^ *//; s/ *$//') || true
    printf '%s' "$line"
    return 0
}

# 除外リストチェック
is_excluded() {
    local file="$1"
    local exclude_file=".dvc-exclude"

    if [ -f "$exclude_file" ]; then
        grep -q "^$file$" "$exclude_file" 2>/dev/null
    else
        return 1
    fi
}

# 除外リストに追加
add_to_exclude_list() {
    local file="$1"
    local exclude_file=".dvc-exclude"

    if is_excluded "$file"; then
        print_info "ファイル $file は既にDVC除外リストに含まれています"
    else
        echo "$file" >> "$exclude_file"
        print_success "ファイル $file をDVC除外リストに追加しました"
        git add "$exclude_file"
    fi
}

# 除外リストから削除
remove_from_exclude_list() {
    local file="$1"
    local exclude_file=".dvc-exclude"

    if is_excluded "$file"; then
        grep -v "^$file$" "$exclude_file" > "${exclude_file}.tmp"
        mv "${exclude_file}.tmp" "$exclude_file"
        print_success "ファイル $file をDVC除外リストから削除しました"
        git add "$exclude_file"
    else
        print_info "ファイル $file はDVC除外リストに含まれていません"
    fi
}

# Git管理チェック
is_git_managed() {
    local file="$1"
    git ls-files --error-unmatch "$file" >/dev/null 2>&1
}

# DVC管理チェック
is_dvc_managed() {
    local file="$1"
    [ -f "${file}.dvc" ]
}

# === 統一config読み込み機能 ===

# CONFIG_LOADED フラグ（重複読み込み防止）
CONFIG_LOADED=${CONFIG_LOADED:-false}

# load_config_from_path: 指定されたconfigファイルを読み込み
# 引数: config_path
load_config_from_path() {
    local config_path="$1"

    if [ ! -f "$config_path" ]; then
        print_error "load_config_from_path: configファイルが見つかりません: $config_path"
        return 1
    fi

    # 安全なconfig読み込み（コメントと空行をスキップ）
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        case "$line" in
            ''|\#*) continue ;;
        esac

        # KEY=VALUE 形式の行のみ処理
        if echo "$line" | grep -q '=' >/dev/null 2>&1; then
            local key="${line%%=*}"
            local value="${line#*=}"

            # bash配列形式の検出と処理
            if [[ "$value" =~ ^\(.*\)$ ]]; then
                # 配列形式: KEY=("val1" "val2" "val3")
                eval "declare -ga $key=$value"
            else
                # スカラー値またはスペース区切り文字列
                if [ -n "$value" ] && [[ "$value" =~ [[:space:]] ]]; then
                    # スペース区切り値を配列に変換
                    eval "declare -ga $key=($value)"
                else
                    # スカラー値
                    eval "declare -g $key=\"$value\""
                fi
            fi
        fi
    done < "$config_path"

    return 0
}

# load_config: 統一的なconfig読み込み
# 引数: (optional: config_path)
# 引数が指定されない場合はcommon.shからの相対パス（../config）を使用
load_config() {
    if [ "$CONFIG_LOADED" = "true" ]; then
        return 0
    fi

    local config_path="${1:-}"

    # configパスが指定されていない場合はcommon.shからの相対パス
    if [ -z "$config_path" ]; then
        local common_dir
        common_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
        config_path="$common_dir/../config"
    fi

    # configファイルを読み込み
    if ! load_config_from_path "$config_path"; then
        return 1
    fi

    # 配列変数の未定義対策（set -u 対応）
    local array_keys=(
        "LATEXMK_OPTIONS"
        "LATEXPAND_OPTIONS"
        "LATEXDIFF_OPTIONS"
        "GIT_DIFF_EXTENSIONS"
        "IMAGE_DIFF_EXTENSIONS"
        "IMAGE_EXTENSIONS"
        "DVC_MANAGED_DIRS"
    )

    for key in "${array_keys[@]}"; do
        if ! declare -p "$key" >/dev/null 2>&1; then
            eval "declare -ga $key=()"
        fi
    done

    CONFIG_LOADED=true
    return 0
}

# get_config_array: 配列設定値を取得
# 引数: array_name
# 出力: 配列の各要素を一行ずつ標準出力へ
get_config_array() {
    local array_name="$1"
    if [ -z "$array_name" ]; then
        print_error "get_config_array: 配列名が必要です"
        return 1
    fi

    if ! load_config; then
        return 1
    fi

    # 配列が定義されているかチェック
    if declare -p "$array_name" >/dev/null 2>&1; then
        eval "local -n arr_ref=$array_name"
        printf '%s\n' "${arr_ref[@]}"
    fi
    return 0
}

# get_config_scalar: スカラー設定値を取得
# 引数: key_name
# 出力: 値を標準出力へ
get_config_scalar() {
    local key_name="$1"
    if [ -z "$key_name" ]; then
        print_error "get_config_scalar: キー名が必要です"
        return 1
    fi

    if ! load_config; then
        return 1
    fi

    # 変数が定義されているかチェック
    if declare -p "$key_name" >/dev/null 2>&1; then
        eval "printf '%s' \"\$$key_name\""
    fi
    return 0
}
