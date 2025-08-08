#!/bin/bash
# DVC復元・移行スクリプト

set -e

# 共通関数の読み込み
source "$(dirname "$0")/common.sh"

# DVC→Git移行（特定ファイル）
restore_to_git() {
    local file="$1"

    check_file_exists "$file"

    if ! is_dvc_managed "$file"; then
        print_error "ファイル $file はDVC管理されていません"
        exit 1
    fi

    print_info "DVC管理ファイルをGit管理に復元中: $file"

    # DVCファイルを復元
    dvc checkout "$file"

    # DVC管理を削除
    rm "${file}.dvc"

    # Gitに追加
    git add "$file"
    git rm "${file}.dvc" 2>/dev/null || true

    # .gitignoreから除去
    if grep -q "^/$file$" .gitignore 2>/dev/null; then
        grep -v "^/$file$" .gitignore > .gitignore.tmp
        mv .gitignore.tmp .gitignore
        git add .gitignore
    fi

    print_success "復元完了: $file"
    print_info "Git管理に戻りました"
}

# 全DVC管理ファイルの一括復元
restore_all_to_git() {
    local dvc_managed_dirs="$1"

    check_dvc_initialized

    print_warning "全てのDVC管理ファイルをGit管理に戻します"
    print_info "この操作により、DVC管理は解除されます"
    echo ""

    # DVC管理ファイルのリスト表示
    echo "== 復元対象ファイル =="
    local file_count=0
    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            echo "$dir/:"
            for dvc_file in $(find "$dir" -name "*.dvc" 2>/dev/null); do
                file=${dvc_file%.dvc}
                echo "  $file"
                file_count=$((file_count + 1))
            done
        fi
    done

    if [ $file_count -eq 0 ]; then
        print_info "DVC管理ファイルが見つかりません"
        return 0
    fi

    echo ""
    read -p "続行しますか? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "キャンセルしました"
        return 0
    fi

    # 一括復元実行
    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            find "$dir" -name "*.dvc" 2>/dev/null | while read dvc_file; do
                file=${dvc_file%.dvc}
                restore_to_git "$file"
            done
        fi
    done

    print_success "全てのファイルをGit管理に復元しました"
}

# DVCの完全削除
remove_dvc_completely() {
    check_dvc_initialized

    print_warning "DVC設定を完全に削除します"
    print_info "この操作は元に戻せません"
    echo ""

    read -p "本当にDVCを削除しますか? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "キャンセルしました"
        return 0
    fi

    # 全ファイルをGitに復元
    restore_all_to_git "$1"

    # DVC設定削除
    print_info "DVC設定を削除中..."
    rm -rf .dvc

    # .gitignoreの清理
    if [ -f ".gitignore" ]; then
        grep -v "^/\.dvc" .gitignore | grep -v "\.dvc$" > .gitignore.tmp
        mv .gitignore.tmp .gitignore
        git add .gitignore
    fi

    print_success "DVC完全削除完了"
}

# メイン実行
case "${1:-}" in
    "file")
        restore_to_git "$2"
        ;;
    "all")
        restore_all_to_git "$2"
        ;;
    "remove")
        remove_dvc_completely "$2"
        ;;
    *)
        echo "使用法: $0 {file|all|remove} [file_path|dvc_managed_dirs]"
        echo ""
        echo "  file <path>    - 指定ファイルをGit管理に復元"
        echo "  all <dirs>     - 全DVC管理ファイルをGit管理に復元"
        echo "  remove         - DVC設定を完全削除"
        exit 1
        ;;
esac
