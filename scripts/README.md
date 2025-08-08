# スクリプト詳細仕様

このディレクトリには、LaTeX + DVC統合ワークフローを支援するスクリプト群が含まれています。

## スクリプト一覧

* `common.sh` - 共通関数・ユーティリティ
* `dvc_init.sh` - DVC初期化処理
* `dvc_validator.sh` - DVC状態確認・接続テスト
* `dvc_restore.sh` - DVC復元・移行機能
* `dvc_remote.sh` - リモートストレージ管理
* `image_manager.sh` - 画像ファイル管理
* `generate_diff.sh` - LaTeX差分生成（既存）

## 共通関数（common.sh）

### 概要

全スクリプトで使用される共通関数とユーティリティを提供。

### 主要関数

#### メッセージ関数

* `print_info(message)` - 情報メッセージ表示
* `print_success(message)` - 成功メッセージ表示
* `print_warning(message)` - 警告メッセージ表示
* `print_error(message)` - エラーメッセージ表示

#### チェック関数

* `check_dvc_initialized()` - DVC初期化状態確認
* `check_file_exists(file)` - ファイル存在確認
* `is_excluded(file)` - DVC除外リスト確認
* `is_git_managed(file)` - Git管理状態確認
* `is_dvc_managed(file)` - DVC管理状態確認

#### 除外リスト管理

* `add_to_exclude_list(file)` - 除外リストに追加
* `remove_from_exclude_list(file)` - 除外リストから削除

### 使用例

```bash
# スクリプト内での読み込み
source "$(dirname "$0")/common.sh"

# 関数の使用
check_file_exists "figures/image.png"
if is_excluded "figures/template.png"; then
    print_info "ファイルは除外設定済み"
fi
```

## DVC初期化（dvc_init.sh）

### 概要

DVCの初期化と既存画像ファイルの自動管理開始を行う。

### 実行フロー

1. DVC初期化（`dvc init`）
2. リモートストレージ設定
3. 既存画像ファイルの検索とDVC追加
4. Git設定のコミット

### 呼び出し形式

```bash
./dvc_init.sh <remote_name> <remote_url> <managed_dirs> <image_extensions>
```

### パラメータ

* `remote_name` - DVCリモート名
* `remote_url` - リモートストレージURL（オプション）
* `managed_dirs` - 管理対象ディレクトリ（スペース区切り）
* `image_extensions` - 画像拡張子（スペース区切り）

### 主要関数

* `execute_dvc_init()` - DVC初期化メイン処理
* `add_existing_images()` - 既存画像の一括追加

## 画像管理（image_manager.sh）

### 概要

画像ファイルの管理状況表示と新規画像のDVC追加処理。

### 主要機能

#### show-changes

新規・変更画像の一覧表示（除外リスト対応）

```bash
./image_manager.sh show-changes "figures" "png jpg"
```

#### add-safe

新規画像のDVC管理への安全な移行

```bash
./image_manager.sh add-safe "figures" "png jpg"
```

#### show-status

画像ファイルの管理状況詳細表示

```bash
./image_manager.sh show-status "figures" "png jpg"
```

### 主要関数

* `show_image_changes()` - 画像変更状況表示
* `add_new_images_safe()` - 安全なDVC追加処理
* `show_image_status()` - 管理状況詳細表示

## DVC復元（dvc_restore.sh）

### 概要

DVC管理ファイルのGit管理への復元とDVC設定の削除。

### 主要機能

#### file

指定ファイルのGit管理復元

```bash
./dvc_restore.sh file "figures/image.png"
```

#### all

全DVC管理ファイルの一括復元

```bash
./dvc_restore.sh all "figures images"
```

#### remove

DVC設定の完全削除

```bash
./dvc_restore.sh remove
```

### 主要関数

* `restore_to_git()` - 単一ファイル復元
* `restore_all_to_git()` - 全ファイル復元
* `remove_dvc_completely()` - DVC完全削除

## リモート管理（dvc_remote.sh）

### 概要

DVCリモートストレージの管理とデータ同期。

### 主要機能

#### add

リモートストレージ追加・更新

```bash
./dvc_remote.sh add "storage" "ssh://user@server/path"
```

#### list

設定済みリモート一覧表示

```bash
./dvc_remote.sh list
```

#### test

リモート接続テスト

```bash
./dvc_remote.sh test "storage"
```

#### push/pull/fetch

データ同期操作

```bash
./dvc_remote.sh push "storage"    # アップロード
./dvc_remote.sh pull "storage"    # ダウンロード
./dvc_remote.sh fetch "storage"   # 確認のみ
```

### 主要関数

* `add_remote()` - リモート追加
* `remove_remote()` - リモート削除
* `list_remotes()` - リモート一覧
* `test_remote()` - 接続テスト
* `sync_data()` - データ同期

## DVC検証（dvc_validator.sh）

### 概要

DVC環境の状態確認と接続テスト。

### 主要機能

#### validate

DVC環境の包括的検証

```bash
./dvc_validator.sh validate "figures images"
```

#### check-connection

リモートストレージ接続確認

```bash
./dvc_validator.sh check-connection "storage"
```

#### status

DVC状態の詳細表示

```bash
./dvc_validator.sh status "figures"
```

### 主要関数

* `validate_dvc()` - DVC環境検証
* `check_dvc_connection()` - 接続確認
* `show_dvc_status()` - 状態表示

## エラーハンドリング

全スクリプトで統一されたエラーハンドリング：

* `set -e` によるエラー時即座終了
* 共通関数による統一メッセージフォーマット
* 適切な終了コード設定
* ユーザー確認プロンプト

## 拡張・カスタマイズ

### 新機能追加

1. `common.sh` に共通関数を追加
2. 専用スクリプトファイルを作成
3. Makefileにターゲット追加

### 設定変更

`latex.config` でパラメータ調整が可能：

```bash
# 管理対象拡張子追加
IMAGE_EXTENSIONS=png jpg jpeg pdf eps svg tiff

# 管理ディレクトリ追加
DVC_MANAGED_DIRS=figures images data plots
```

## デバッグ

スクリプトデバッグ時の推奨方法：

```bash
# デバッグモード実行
bash -x ./scripts/image_manager.sh show-status "figures" "png"

# 関数単体テスト
source scripts/common.sh
check_file_exists "test.png"
```

各スクリプトは独立して実行可能で、Makefileを経由せずに直接テストできます。
