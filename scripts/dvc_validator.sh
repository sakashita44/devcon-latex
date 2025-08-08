#!/bin/bash
# DVCバリデーションスクリプト

set -e

# 共通関数の読み込み
source "$(dirname "$0")/common.sh"

# DVC状態確認
validate_dvc() {
    local dvc_managed_dirs="$1"

    echo "== DVC状態確認 =="

    if command -v dvc >/dev/null 2>&1; then
        print_success "DVC環境: 利用可能"

        if [ -d ".dvc" ]; then
            print_success "DVC: 初期化済み"

            local remote_count=$(dvc remote list | wc -l)
            if [ $remote_count -gt 0 ]; then
                print_success "リモート設定: $remote_count 個"
                dvc remote list | sed 's/^/    /'
            else
                print_warning "リモート設定: なし"
            fi

            local managed_files=0
            for dir in $dvc_managed_dirs; do
                if [ -d "$dir" ]; then
                    local dir_files=$(find "$dir" -name "*.dvc" | wc -l)
                    managed_files=$((managed_files + dir_files))
                    print_success "$dir/: $dir_files 個のDVC管理ファイル"
                else
                    print_info "$dir/: ディレクトリ存在せず"
                fi
            done
            print_success "合計DVC管理ファイル: $managed_files 個"
        else
            print_warning "DVC: 未初期化"
        fi
    else
        print_error "DVC環境: dvc コマンドが見つかりません"
        exit 1
    fi
}

# DVC接続確認
check_dvc_connection() {
    local dvc_remote_name="$1"

    echo "=== DVC接続確認 ==="

    check_dvc_initialized

    print_info "リモートストレージへの接続を確認中..."

    if dvc remote list | grep -q "$dvc_remote_name"; then
        print_success "リモート $dvc_remote_name が設定されています"

        if dvc status -r "$dvc_remote_name" >/dev/null 2>&1; then
            print_success "リモートストレージに正常に接続できます"
        else
            print_error "リモートストレージに接続できません"
            print_info "認証情報やURLを確認してください"
            exit 1
        fi
    else
        print_error "リモート $dvc_remote_name が設定されていません"
        print_info "'dvc remote add -d $dvc_remote_name <URL>' で設定してください"
        exit 1
    fi
}

# DVC状態表示
show_dvc_status() {
    local dvc_managed_dirs="$1"

    echo "=== DVC状態確認 ==="

    if [ -d ".dvc" ]; then
        print_success "DVC: 初期化済み"
        echo ""

        echo "== DVC管理ファイル =="
        dvc status
        echo ""

        echo "== リモート設定 =="
        dvc remote list
        echo ""

        echo "== 管理対象画像ファイル =="
        for dir in $dvc_managed_dirs; do
            if [ -d "$dir" ]; then
                echo "$dir/:"
                find "$dir" -name "*.dvc" | sed 's/\.dvc$//' | sed 's/^/  /' || echo "  なし"
            fi
        done
    else
        print_warning "DVC: 未初期化"
        echo ""
        print_info "'make dvc-init' でDVCを初期化できます"
    fi
}

# メイン実行
case "${1:-}" in
    "validate")
        validate_dvc "$2"
        ;;
    "check-connection")
        check_dvc_connection "$2"
        ;;
    "status")
        show_dvc_status "$2"
        ;;
    *)
        echo "使用法: $0 {validate|check-connection|status} <dvc_managed_dirs_or_remote_name>"
        exit 1
        ;;
esac
