#!/bin/bash
# DVCリモート管理スクリプト

set -e

# 共通関数の読み込み
source "$(dirname "$0")/common.sh"

# リモート追加
add_remote() {
    local remote_name="$1"
    local remote_url="$2"

    check_dvc_initialized

    if [ -z "$remote_name" ] || [ -z "$remote_url" ]; then
        print_error "リモート名とURLが必要です"
        exit 1
    fi

    print_info "DVCリモートを設定中..."
    print_info "リモート名: $remote_name"
    print_info "URL: $remote_url"

    # リモート追加
    if dvc remote add "$remote_name" "$remote_url" 2>/dev/null; then
        print_success "リモート追加完了: $remote_name"
    else
        print_info "リモート更新中..."
        dvc remote modify "$remote_name" url "$remote_url"
        print_success "リモート更新完了: $remote_name"
    fi

    # デフォルトリモートに設定
    dvc remote default "$remote_name"
    print_success "デフォルトリモートに設定: $remote_name"

    # Git設定をコミット
    git add .dvc/config
    if [ -n "$(git status --porcelain .dvc/config)" ]; then
        git commit -m "feat: DVCリモート設定 ($remote_name)"
        print_success "リモート設定をコミットしました"
    fi
}

# リモート削除
remove_remote() {
    local remote_name="$1"

    check_dvc_initialized

    if [ -z "$remote_name" ]; then
        print_error "リモート名が必要です"
        exit 1
    fi

    if ! dvc remote list | grep -q "^$remote_name"; then
        print_error "リモート $remote_name が見つかりません"
        exit 1
    fi

    print_warning "リモート $remote_name を削除します"
    read -p "続行しますか? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "キャンセルしました"
        return 0
    fi

    dvc remote remove "$remote_name"
    print_success "リモート削除完了: $remote_name"

    # Git設定をコミット
    git add .dvc/config
    if [ -n "$(git status --porcelain .dvc/config)" ]; then
        git commit -m "chore: DVCリモート削除 ($remote_name)"
        print_success "リモート設定をコミットしました"
    fi
}

# リモート一覧表示
list_remotes() {
    check_dvc_initialized

    echo "=== DVCリモート一覧 ==="

    if dvc remote list | grep -q .; then
        dvc remote list | while read line; do
            if echo "$line" | grep -q '\*'; then
                print_success "$line （デフォルト）"
            else
                echo "  $line"
            fi
        done
    else
        print_info "設定されたリモートはありません"
    fi
}

# DVCリモート接続チェック用ヘルパー関数
check_dvc_connection() {
    local status_output="$1"
    if echo "$status_output" | grep -q "new:\|modified:\|deleted:\|Data and pipelines are up to date\|not in cache"; then
        print_success "リモート接続: 正常"
    else
        print_error "リモート接続: 失敗"
        print_info "認証情報やURLを確認してください"
        exit 1
    fi
}

# リモート接続テスト
test_remote() {
    local remote_name="$1"

    check_dvc_initialized

    if [ -z "$remote_name" ]; then
        # デフォルトリモートをテスト
        print_info "デフォルトリモートの接続をテスト中..."
        local status_output
        status_output="$(dvc status --cloud 2>&1)"
        check_dvc_connection "$status_output"
    else
        # 指定リモートをテスト
        if ! dvc remote list | grep -q "^$remote_name"; then
            print_error "リモート $remote_name が見つかりません"
            exit 1
        fi

        print_info "リモート $remote_name の接続をテスト中..."
        local status_output
        status_output="$(dvc status --cloud -r "$remote_name" 2>&1)"
        check_dvc_connection "$status_output"
    fi
}
            print_info "認証情報やURLを確認してください"
            exit 1
        fi
    fi
}

# プッシュ・プル操作
sync_data() {
    local operation="$1"
    local remote_name="$2"

    check_dvc_initialized

    case "$operation" in
        "push")
            print_info "データをリモートにプッシュ中..."
            if [ -n "$remote_name" ]; then
                dvc push -r "$remote_name"
            else
                dvc push
            fi
            print_success "プッシュ完了"
            ;;
        "pull")
            print_info "データをリモートからプル中..."
            if [ -n "$remote_name" ]; then
                dvc pull -r "$remote_name"
            else
                dvc pull
            fi
            print_success "プル完了"
            ;;
        "fetch")
            print_info "リモートデータを確認中..."
            if [ -n "$remote_name" ]; then
                dvc fetch -r "$remote_name"
            else
                dvc fetch
            fi
            print_success "フェッチ完了"
            ;;
        *)
            print_error "無効な操作: $operation"
            exit 1
            ;;
    esac
}

# メイン実行
case "${1:-}" in
    "add")
        add_remote "$2" "$3"
        ;;
    "remove")
        remove_remote "$2"
        ;;
    "list")
        list_remotes
        ;;
    "test")
        test_remote "$2"
        ;;
    "push"|"pull"|"fetch")
        sync_data "$1" "$2"
        ;;
    *)
        echo "使用法: $0 {add|remove|list|test|push|pull|fetch} [args...]"
        echo ""
        echo "  add <name> <url>  - リモート追加"
        echo "  remove <name>     - リモート削除"
        echo "  list             - リモート一覧"
        echo "  test [name]      - リモート接続テスト"
        echo "  push [name]      - データプッシュ"
        echo "  pull [name]      - データプル"
        echo "  fetch [name]     - データフェッチ"
        exit 1
        ;;
esac
