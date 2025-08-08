#!/bin/bash
# 画像ファイル管理スクリプト

set -e

# 共通関数の読み込み
source "$(dirname "$0")/common.sh"

# 新規・変更画像の表示
show_image_changes() {
    local dvc_managed_dirs="$1"
    local image_extensions="$2"

    echo "== 新規画像ファイル =="
    local found=0

    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            for ext in $image_extensions; do
                while read file; do
                    if [ -z "$file" ]; then
                        continue
                    fi
                    if ! is_dvc_managed "$file"; then
                        if is_excluded "$file"; then
                            echo "  除外: $file （DVC除外マーク済み）"
                        else
                            echo "  新規: $file"
                            found=1
                        fi
                    fi
                done < <(find "$dir" -type f -name "*.$ext" 2>/dev/null)
            done
        fi
    done

    if [ $found -eq 0 ]; then
        echo "  なし"
    fi

    echo "== 変更されたDVC管理画像 =="
    if git status --porcelain 2>/dev/null | grep -E "\.dvc$" | sed 's/^/  /' | head -10; then
        true
    else
        echo "  なし"
    fi
}

# 新規画像のDVC追加（安全版・除外リスト対応）
add_new_images_safe() {
    local dvc_managed_dirs="$1"
    local image_extensions="$2"

    print_info "画像ファイルをDVC管理に移行中（コピーベース）..."

    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            for ext in $image_extensions; do
                find "$dir" -type f -name "*.$ext" 2>/dev/null | while read file; do
                    if ! is_dvc_managed "$file"; then
                        if is_excluded "$file"; then
                            echo "  スキップ: $file （除外リスト指定）"
                        else
                            echo "  処理中: $file"
                            if is_git_managed "$file"; then
                                echo "    Git管理から除外中..."
                                git rm --cached "$file"
                            fi
                            echo "    DVC管理に追加中..."
                            dvc add "$file"
                        fi
                    fi
                done
            done
        fi
    done

    print_info "DVCファイルをGitに追加中..."
    for dir in $dvc_managed_dirs; do
        git add "$dir"/*.dvc .gitignore 2>/dev/null || true
    done
}

# 画像ファイルの管理状況表示
show_image_status() {
    local dvc_managed_dirs="$1"
    local image_extensions="$2"

    echo "=== 画像ファイル管理状況 ==="
    echo ""

    echo "== Git管理画像 =="
    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            echo "$dir/:"
            for ext in $image_extensions; do
                find "$dir" -type f -name "*.$ext" 2>/dev/null | while read file; do
                    if ! is_dvc_managed "$file"; then
                        if is_excluded "$file"; then
                            echo "  $file （DVC除外マーク済み）"
                        else
                            echo "  $file"
                        fi
                    fi
                done
            done
        fi
    done

    echo ""
    echo "== DVC管理画像 =="
    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            echo "$dir/:"
            find "$dir" -name "*.dvc" 2>/dev/null | sed 's/\.dvc$//' | sed 's/^/  /' || echo "  なし"
        fi
    done

    echo ""
    echo "== DVC除外設定 =="
    if [ -f ".dvc-exclude" ]; then
        local exclude_count=$(grep -v '^#' .dvc-exclude | grep -v '^$' | wc -l)
        echo "除外ファイル数: $exclude_count"
        echo "除外リスト:"
        grep -v '^#' .dvc-exclude | grep -v '^$' | sed 's/^/  /' || echo "  なし"
    else
        echo "除外設定なし"
    fi
}

# メイン実行
case "${1:-}" in
    "show-changes")
        show_image_changes "$2" "$3"
        ;;
    "add-safe")
        add_new_images_safe "$2" "$3"
        ;;
    "show-status")
        show_image_status "$2" "$3"
        ;;
    *)
        echo "使用法: $0 {show-changes|add-safe|show-status} <dvc_managed_dirs> <image_extensions>"
        exit 1
        ;;
esac
