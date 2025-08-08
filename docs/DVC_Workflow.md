# 論文執筆ワークフロー（DVC統合版）

## 目的

論文執筆における大容量画像ファイルの効率的管理と、レビューサイクルの最適化

## 概要

これは基本的な[論文執筆ワークフロー](workflow.md)の発展形です。DVCを使用して大容量画像ファイルを効率的に管理し、Git + DVC統合によるバージョン管理を実現します。基本ワークフローに加えて、画像ファイルの管理機能が追加されています。

**前提**: 基本的な論文執筆ワークフローを理解している方向けです。まずは[workflow.md](workflow.md)を参照してください。

## DVCを使用するかの判断基準

### DVCを使用しない場合（基本ワークフロー）

以下の条件に当てはまる場合は、[基本ワークフロー](workflow.md)で十分です:

- 画像ファイルが少ない（10個未満）
- 画像サイズが小さい（1つあたり1MB未満）
- 個人プロジェクトまたは小規模チーム
- リモートストレージが不要

### DVCを使用する場合（DVC統合ワークフロー）

以下の条件に当てはまる場合は、DVCの使用を推奨します:

- 大容量画像ファイルが多数ある（合計100MB以上）
- 高解像度画像や動画ファイルを含む
- 共同研究やチーム開発
- リモートストレージでのバックアップが必要
- 公開リポジトリでデータを分離したい

## DVC統合ワークフロー

### 1. 初期設定

リポジトリをクローンし、DVC環境をセットアップ

```bash
git clone <リポジトリURL>
cd <リポジトリ名>

# 設定ファイル作成
cp latex.config.example latex.config

# DVC初期化（大容量画像がある場合）
make dvc-init

# リモートストレージ設定
make dvc-remote-add NAME=storage URL=ssh://user@server/path
make dvc-remote-test  # 接続確認
```

### 2. 初回バージョンの作成

論文の初稿を完成させ、画像ファイルを管理対象に追加

```bash
# 画像ファイルをDVC管理に追加
make dvc-add-images

# LaTeX文書をビルド
make build

# データをリモートにプッシュ
make dvc-push

# 初回レビュー用タグを作成
git add .
git commit -m "feat: 初稿完成"
git tag -a v1.0 -m "Initial version for review"
git push origin v1.0
```

### 3. 執筆とコミット

論文の執筆を進め、画像管理と併せてコミット

```bash
# 新しい画像ファイルを追加
# figures/ に画像ファイルを配置
make dvc-add-images  # 新規画像をDVC管理に追加

# LaTeX文書をビルド
make build

# データ同期
make dvc-push        # 画像をリモートにアップロード

# Gitコミット
git add .
git commit -m "feat: 序論セクションと図表を追加"
```

### 4. レビュー前のバージョン作成

次のレビュー用に新しいタグを作成

```bash
# 最新状態を確認
make validate        # 全体状況確認
make show-image-status  # 画像管理状況確認

# データ同期
make dvc-push

# レビュー用タグ作成
git tag -a v2.0 -m "Second version for review"
git push origin v2.0
```

### 5. 差分の確認

差分計算ツールを使用して変更点を確認

```bash
# 自動差分計算（基本ワークフローと同じ）
make diff

# または特定バージョン間の差分
make diff-pdf BASE=v1.0 CHANGED=v2.0
```

### 6. チーム作業での画像取得

共同作業者が最新の画像ファイルを取得

```bash
# リポジトリを更新
git pull

# DVC管理ファイルを取得
make dvc-pull

# 文書をビルド
make build
```

## コミットメッセージ規則

基本ワークフローと同じ規則を使用:

- `feat:` 新機能・新セクション・画像追加
- `fix:` バグ修正・誤字修正・画像修正
- `refactor:` 構成変更・リファクタリング
- `docs:` ドキュメント変更
- `style:` 書式・スタイル変更

## タグ命名規則

基本ワークフローと同じ規則:

- `v1.0`, `v2.0`: メジャーレビュー版
- `v1.1`, `v1.2`: マイナー修正版

## 差分確認方法

### テキスト差分（Git）

```bash
git diff v1.0 v2.0
```

### 視覚的差分（PDF）

基本ワークフローと同じ差分生成機能を使用:

```bash
# 自動差分計算
make diff

# 特定バージョン間の差分
make diff-pdf BASE=v1.0 CHANGED=v2.0
```

生成される`diff_output/diff.pdf`を確認:

- 赤文字・取り消し線: 削除された内容
- 青文字・下線: 追加された内容

## ファイル管理

### DVC管理ファイル

- `figures/*.dvc` - DVC管理ファイル（自動生成）
- `.dvc/` - DVC設定ディレクトリ
- `.dvcignore` - DVC除外設定

### 差分出力ファイル（基本ワークフローと同じ）

- `diff_output/git_diff.txt`: Git差分（テキスト形式）
- `diff_output/diff.tex`: LaTeX差分ファイル
- `diff_output/diff.pdf`: 視覚的差分PDF

### 画像ファイル状況確認

```bash
# 画像管理状況の確認
make show-image-status

# DVC状態確認
make dvc-status

# 全体状況確認
make validate
```

## 公開リポジトリ対応

研究リポジトリを公開する際の推奨手順:

### 1. 画像ファイルの分類

```bash
# テンプレート画像をGit管理に残す
make dvc-exclude-image FILE=figures/template.png
make dvc-exclude-image FILE=figures/logo.png

# 作業用画像はDVC管理を継続
# （自動的にDVC管理される）
```

### 2. 公開前の確認

```bash
# 管理状況確認
make show-image-status

# 最終ビルド確認
make build

# データ同期
make dvc-push
```

### 3. 公開時の注意点

- **テンプレート画像**: Git管理（公開リポジトリで利用可能）
- **作業用画像**: DVC管理（リモートストレージ経由でアクセス）
- **論文PDF**: 通常のGit管理

## DVC設定ファイル

`latex.config` で以下を設定可能:

```bash
# LaTeX設定
MAIN_TEX=main.tex
LATEX_ENGINE=lualatex

# DVC設定
DVC_MANAGED_DIRS=figures images data
IMAGE_EXTENSIONS=png jpg jpeg pdf eps svg
DVC_REMOTE_URL=ssh://user@server/path/to/storage
```

## トラブルシューティング

### DVC接続エラー

```bash
# 接続確認
make dvc-remote-test

# リモート設定確認
make dvc-remote-list
```

### 画像ファイルが見つからない

```bash
# DVC データの復元
make dvc-pull

# または特定ファイルの復元
dvc checkout figures/missing-image.png
```

### DVC完全削除

```bash
# 全てをGit管理に戻してDVC削除
make dvc-remove
```

## 利用可能なコマンド一覧

### 基本機能（基本ワークフローと同じ）

- `make build` - LaTeX文書をビルド
- `make build-safe` - バリデーション付きビルド
- `make watch` - ファイル変更を監視して自動ビルド
- `make clean` - 出力ファイルをクリーンアップ
- `make diff` - 差分PDF生成

### DVC機能

- `make dvc-init` - DVCを初期化し既存画像を管理対象に追加
- `make dvc-status` - DVC状態を確認
- `make dvc-add-images` - 新規・変更画像をDVC管理に追加
- `make show-image-status` - 画像ファイルの管理状況を表示
- `make dvc-push/pull/fetch` - データ同期
- `make dvc-remote-add NAME=name URL=url` - リモート追加
- `make validate` - 全体の状態確認

## 関連ツール

- **基本ワークフロー**: [`workflow.md`](workflow.md) - 基本的な論文執筆ワークフロー
- **差分計算ツール**: [`README_DiffTool.md`](README_DiffTool.md) - 差分計算の詳細
- **設定例**: [`Configuration_Examples.md`](Configuration_Examples.md) - 実用的な設定例
- **スクリプト仕様**: [`../scripts/README.md`](../scripts/README.md) - 各スクリプトの技術仕様
