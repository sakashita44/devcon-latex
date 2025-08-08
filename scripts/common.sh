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
