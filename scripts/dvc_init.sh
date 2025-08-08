#!/bin/bash
# DVC初期化とセットアップスクリプト

set -e

# 設定の読み込み
source "$(dirname "$0")/common.sh"

# DVC初期化の実行
execute_dvc_init() {
    local dvc_remote_name="$1"
    local dvc_remote_url="$2"
    local dvc_managed_dirs="$3"
    local image_extensions="$4"

    echo "1/4: DVCを初期化中..."
    if [ ! -d ".dvc" ]; then
        dvc init
        echo "  DVC初期化完了"
    else
        echo "  DVC既に初期化済み"
    fi

    echo "2/4: リモートストレージを設定中..."
    if [ -n "$dvc_remote_url" ]; then
        dvc remote add -d "$dvc_remote_name" "$dvc_remote_url" 2>/dev/null || \
        dvc remote modify "$dvc_remote_name" url "$dvc_remote_url"
        echo "  リモート $dvc_remote_name を設定: $dvc_remote_url"
    else
        echo "  リモートURL未指定のためスキップ"
        echo "  後で 'dvc remote add -d $dvc_remote_name <URL>' を実行してください"
    fi

    echo "3/4: 既存画像ファイルを検索中..."
    add_existing_images "$dvc_managed_dirs" "$image_extensions"

    echo "4/4: 設定をGitに追加中..."
    git add .dvc .gitignore
    if [ -n "$(git status --porcelain .dvc .gitignore)" ]; then
        git commit -m "feat: DVC初期化と既存画像の管理開始"
        echo "  DVC設定をコミットしました"
    else
        echo "  コミットする変更がありません"
    fi
}

# 既存画像ファイルのDVC追加
add_existing_images() {
    local dvc_managed_dirs="$1"
    local image_extensions="$2"

    for dir in $dvc_managed_dirs; do
        if [ -d "$dir" ]; then
            echo "  $dir/ 内の画像を検索中..."
            for ext in $image_extensions; do
                find "$dir" -type f -name "*.$ext" 2>/dev/null | while read file; do
                    if [ ! -f "${file}.dvc" ]; then
                        echo "    追加: $file"
                        dvc add "$file"
                    else
                        echo "    既存: $file （DVC管理済み）"
                    fi
                done
            done
        else
            echo "  $dir/ が存在しません。スキップします"
        fi
    done
}

# メイン実行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    execute_dvc_init "$@"
fi
