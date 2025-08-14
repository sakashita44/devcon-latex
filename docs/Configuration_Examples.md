# 設定例とベストプラクティス

## このドキュメントについて

このドキュメントは，`latex.config`ファイルの設定例を提供します．以下のワークフローと併せて利用してください:

* **基本的な論文執筆**: [`workflow.md`](workflow.md) - 基本ワークフローを先に確認
* **DVC画像管理**: [`DVC_Workflow.md`](DVC_Workflow.md) - DVCで画像などを管理する場合の設定例
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

### 画像管理方法の選択

**適用場面**: [`DVC_Workflow.md`](DVC_Workflow.md)の画像管理最適化ワークフロー

```bash
# latex.config
MAIN_TEX=paper.tex
DVC_MANAGED_DIRS=figures
IMAGE_EXTENSIONS=png jpg pdf eps
DVC_REMOTE_NAME=storage
DVC_REMOTE_URL=ssh://user@server/paper-images

# .dvc-exclude に追加するファイル例（Git管理に変更）
# figures/logo.png          # 10KB, 年1回変更
# figures/template.jpg      # 50KB, 初回作成後変更なし
# figures/diagram-base.pdf  # 100KB, 完成済み静的図表
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

### 論文投稿・画像管理最適化時

```bash
# 1. 小容量かつ変更頻度低の画像をGit管理に変更
make dvc-exclude-image FILE=figures/small-logo.png

# 2. 静的テンプレート画像をGit管理に変更
make dvc-restore-file FILE=figures/template.png

# 3. 管理状況確認
make show-image-status

# 4. 最適化された管理状態で運用
# Git管理: 小容量 + 変更頻度低
# DVC管理: 大容量 or 変更頻度高 or 全体量大
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
├── 01-introduction/          # 使用先のtexファイル名をディレクトリ名に
│   ├── overview.png          # 概要図
│   └── research-flow.pdf     # 研究フロー
├── 02-method/
│   ├── algorithm.png         # アルゴリズム
│   └── architecture.pdf      # システム構成
└── shared/
    ├── logo.png              # ロゴ（公開OK）
    └── template.pdf          # テンプレート（公開OK）
```

### 3. 画像管理の最適化

```bash
# チーム共通の管理方針設定
# 以下を .dvc-exclude に追加（Git管理に変更）
figures/shared/logo.png          # 10KB, 年1回変更
figures/shared/template.pdf      # 50KB, 静的テンプレート
figures/shared/icon.png          # 5KB, 変更なし

# 以下はDVC管理を継続（デフォルト）
# - 変更頻度高: 実験結果ファイル
# - 大容量: 高解像度画像
# - 量が多: 大量の図表ファイル
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

### 2. 管理方針に基づくファイル分類

* **Git管理対象**: 小容量ファイル（1MB未満），変更頻度の低いファイル
* **DVC管理対象**: 大容量ファイル（1MB以上），頻繁に変更されるファイル
* **パフォーマンス最適化**: ファイルサイズと変更頻度による適切な管理方法選択

### 3. アクセス制御

* チームメンバーのみアクセス可能な設定
* 定期的なアクセス権限見直し
* ログ監視の実装

## 画像管理方法の判断基準

### Git管理を選択する場合

以下の **すべて** に該当するファイル:

* ファイルサイズが小さい (1MB未満)
* 変更頻度が低い (月1回未満)
* チーム全体で頻繁にアクセス

### DVC管理を選択する場合

以下の **いずれか** に該当する場合:

* 変更頻度が高い
* ファイルサイズが大きい (1MB以上)
* 画像ファイル全体の容量が大きい (100MB以上)

### 実用例

```bash
# Git管理の例
figures/logo.png          # 10KB, 年1回変更
figures/university.png    # 50KB, 変更なし
figures/template.pdf      # 100KB, 初回作成後変更なし

# DVC管理の例 (デフォルト)
figures/experiment-*.png  # 500KB, 実験のたびに更新
figures/hires-photo.jpg   # 5MB, 高解像度写真
figures/simulation/*.png  # 各100KB x 200ファイル = 20MB
```

### ファイルサイズによる分類

```bash
# 1MB未満かつ変更頻度低 → Git管理
make dvc-exclude-image FILE=figures/small-logo.png

# 1MB以上 or 変更頻度高 → DVC管理推奨（デフォルト）
# 自動的にDVC管理される
```

### 変更頻度による分類

```bash
# 小サイズかつ変更頻度低 → Git管理
make dvc-exclude-image FILE=figures/static-diagram.png

# 変更頻度高 or 大容量 → DVC管理
# 実験結果や大容量ファイルはDVC管理を継続
```

### チーム共有の考慮

```bash
# 小サイズかつアクセス頻度高かつ変更頻度低 → Git管理
make dvc-exclude-image FILE=figures/team-logo.png

# 専門的な図表やデータ → DVC管理
# 大容量または頻繁変更ファイルはDVC管理
```

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

設定完了後は，以下のワークフローを参照して実際の作業を開始してください:

* **基本的な論文執筆**: [`workflow.md`](workflow.md) - 標準的なワークフロー
* **DVC画像管理**: [`DVC_Workflow.md`](DVC_Workflow.md) - 大容量画像を含む場合のワークフロー
* **差分ツール**: [`README_DiffTool.md`](README_DiffTool.md) - 差分生成機能の詳細
* **スクリプト仕様**: [`../scripts/README.md`](../scripts/README.md) - 技術的な詳細仕様

問題が発生した場合は，各ワークフローのトラブルシューティングセクションを参照してください．
