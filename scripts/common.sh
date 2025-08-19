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
