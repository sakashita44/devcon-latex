# 設定例とベストプラクティス

## このドキュメントについて

このドキュメントは、LaTeX論文執筆環境の様々な使用場面に応じた設定例を提供します。以下のワークフローと併せて利用してください:

* **基本的な論文執筆**: [`workflow.md`](workflow.md) - 基本ワークフローを先に確認
* **DVC画像管理**: [`DVC_Workflow.md`](DVC_Workflow.md) - 大容量画像がある場合の設定例
* **差分ツール**: [`README_DiffTool.md`](README_DiffTool.md) - 差分生成の詳細設定

## 使い方の流れ

1. 自分の環境に合う設定例を選択
2. `latex.config`ファイルを作成・編集
3. 対応するワークフローを実行
4. 必要に応じてカスタマイズ

## 一般的な設定例

### シンプルな論文執筆（DVC不使用）

**適用場面**: [`workflow.md`](workflow.md)の基本ワークフロー（DVC機能なし）

```bash
# latex.config
MAIN_TEX=main.tex
# DVC関連設定（すべて空白でOK）
IMAGE_EXTENSIONS=
DVC_MANAGED_DIRS=
DVC_REMOTE_NAME=
DVC_REMOTE_URL=
LATEX_ENGINE=lualatex
ENABLE_LATEXINDENT=true
```

この設定では：

* 画像ファイルは通常のGit管理
* DVC関連コマンド（`make dvc-init`等）は使用しない
* 基本的なLaTeX機能のみ利用

### 基本的なラボ環境

**適用場面**: [`workflow.md`](workflow.md)の基本ワークフロー + 少量のDVC使用

```bash
# latex.config
MAIN_TEX=main.tex
DVC_MANAGED_DIRS=figures
IMAGE_EXTENSIONS=png jpg pdf
DVC_REMOTE_NAME=lab-storage
DVC_REMOTE_URL=ssh://user@lab-server/storage/latex-projects
LATEX_ENGINE=lualatex
ENABLE_LATEXINDENT=true
```

### 大規模プロジェクト

**適用場面**: [`DVC_Workflow.md`](DVC_Workflow.md)の完全DVC統合ワークフロー

```bash
# latex.config
MAIN_TEX=dissertation.tex
DVC_MANAGED_DIRS=figures images data plots results
IMAGE_EXTENSIONS=png jpg jpeg pdf eps svg tiff
DVC_REMOTE_NAME=cloud-storage
DVC_REMOTE_URL=s3://research-bucket/dissertation-data
LATEX_ENGINE=lualatex
BIBTEX_ENGINE=biber
```

### 公開リポジトリ対応

**適用場面**: [`DVC_Workflow.md`](DVC_Workflow.md)の公開リポジトリワークフロー

```bash
# latex.config
MAIN_TEX=paper.tex
DVC_MANAGED_DIRS=figures
IMAGE_EXTENSIONS=png jpg pdf eps
DVC_REMOTE_NAME=private-storage
DVC_REMOTE_URL=ssh://user@private-server/paper-images

# .dvc-exclude に追加するファイル例
# figures/logo.png          # 研究室ロゴ（公開OK）
# figures/template.jpg      # テンプレート画像（公開OK）
# figures/diagram-base.pdf  # 基本図表（公開OK）
```

## ワークフロー例

### 論文執筆開始時

```bash
# 1. 環境セットアップ
cp latex.config.example latex.config
# latex.config を編集

# 2. DVC初期化
make dvc-init

# 3. リモート設定
make dvc-remote-add NAME=storage URL=ssh://user@server/path

# 4. 初期状態確認
make validate
```

### 日常的な作業

```bash
# 新しい画像追加時
make dvc-add-images

# リモートに保存
make dvc-push

# 他の環境での作業開始時
make dvc-pull

# 現在の状況確認
make show-image-status
```

### 共同研究者との共有

```bash
# 1. Git リポジトリ共有（通常通り）
git clone <repository-url>
cd <project>

# 2. 設定ファイル作成（各自の環境に合わせて）
cp latex.config.example latex.config
# 設定を編集

# 3. DVC データ取得
make dvc-pull

# 4. 環境確認
make validate
```

### 論文投稿・公開時

```bash
# 1. 公開用画像の除外設定
make dvc-exclude-image FILE=figures/confidential-data.png

# 2. テンプレート画像をGit管理に戻す
make dvc-restore-file FILE=figures/university-logo.png

# 3. 最終確認
make show-image-status

# 4. 公開リポジトリ作成
# Git管理ファイルのみ含まれる
```

## ストレージ設定例

### SSH接続

```bash
# SSH鍵認証設定済みの場合
DVC_REMOTE_URL=ssh://username@server.example.com/path/to/storage

# ポート指定
DVC_REMOTE_URL=ssh://username@server.example.com:2222/path/to/storage
```

### Amazon S3

```bash
# 基本設定
DVC_REMOTE_URL=s3://bucket-name/project-folder

# リージョン指定が必要な場合
# dvc remote modify storage region us-west-2
```

### Google Drive

```bash
# Google Drive フォルダID使用
DVC_REMOTE_URL=gdrive://1BxWjKRjCk_XYZ...folder-id

# 認証設定が別途必要
# dvc remote modify storage gdrive_acknowledge_abuse true
```

### ローカルネットワークストレージ

```bash
# NAS等
DVC_REMOTE_URL=/mnt/shared/latex-projects

# ネットワークドライブ（Windows）
DVC_REMOTE_URL=Z:/shared/latex-projects
```

## チーム開発のベストプラクティス

### 1. 設定ファイル管理

* `latex.config.example` を適切に維持
* 各メンバーは個人用 `latex.config` を作成
* 共通設定は example ファイルで管理

### 2. 画像ファイル命名規則

```bash
# 推奨命名規則
figures/
├── 01-introduction/
│   ├── overview.png          # 概要図
│   └── research-flow.pdf     # 研究フロー
├── 02-method/
│   ├── algorithm.png         # アルゴリズム
│   └── architecture.pdf      # システム構成
└── shared/
    ├── logo.png              # ロゴ（公開OK）
    └── template.pdf          # テンプレート（公開OK）
```

### 3. 除外設定の運用

```bash
# チーム共通の除外設定
# 以下を .dvc-exclude に追加
figures/shared/logo.png
figures/shared/template.pdf
figures/shared/university-logo.png

# 個人データは個別に除外
make dvc-exclude-image FILE=figures/personal/draft.png
```

### 4. データバックアップ

```bash
# 定期的なプッシュ
make dvc-push

# 重要なマイルストーン時
git tag -a v1.0 -m "First complete draft"
make dvc-push
git push origin v1.0
```

## トラブルシューティング

### DVC関連

#### ロックファイルエラー

```bash
# DVCロック削除
rm .dvc/tmp/lock

# または強制実行
dvc add figures/image.png --force
```

#### 認証エラー

```bash
# SSH鍵確認
ssh-add -l

# 接続テスト
make dvc-remote-test

# 認証情報再設定
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### 容量エラー

```bash
# キャッシュクリーンアップ
dvc cache dir
dvc gc --workspace

# 古いバージョン削除
dvc cache size
dvc gc --cloud
```

### LaTeX関連

#### ビルドエラー

```bash
# 依存関係確認
make validate-latex

# キャッシュクリア
make clean
make build

# 詳細エラー確認
latexmk -pdf -verbose main.tex
```

#### 画像参照エラー

```bash
# 画像ファイル確認
make show-image-status

# DVCファイル復元
make dvc-pull

# 特定画像復元
dvc checkout figures/missing-image.png
```

## セキュリティ考慮事項

### 1. 認証情報管理

* SSH鍵は適切に管理
* AWS認証情報は環境変数で設定
* パスワードをコミットしない

### 2. 機密データ保護

* 機密画像は除外設定を確実に
* 公開前に `show-image-status` で確認
* プライベートリモートストレージ使用

### 3. アクセス制御

* チームメンバーのみアクセス可能な設定
* 定期的なアクセス権限見直し
* ログ監視の実装

## パフォーマンス最適化

### 1. ファイルサイズ管理

```bash
# 大容量ファイル確認
find figures -type f -size +10M

# 圧縮設定
# 画像は適切な解像度に調整
# PDFは最適化済みを使用
```

### 2. ネットワーク最適化

```bash
# 並列アップロード設定
dvc remote modify storage jobs 4

# 部分同期
dvc push figures/chapter1/
```

### 3. キャッシュ管理

```bash
# キャッシュサイズ確認
dvc cache size

# 定期的なクリーンアップ
dvc gc --workspace --cloud
```

## 関連ドキュメント

設定完了後は、以下のワークフローを参照して実際の作業を開始してください:

* **基本的な論文執筆**: [`workflow.md`](workflow.md) - 標準的なワークフロー
* **DVC画像管理**: [`DVC_Workflow.md`](DVC_Workflow.md) - 大容量画像を含む場合のワークフロー
* **差分ツール**: [`README_DiffTool.md`](README_DiffTool.md) - 差分生成機能の詳細
* **スクリプト仕様**: [`../scripts/README.md`](../scripts/README.md) - 技術的な詳細仕様

問題が発生した場合は、各ワークフローのトラブルシューティングセクションを参照してください。
