# 論文執筆ワークフロー

## 目的

論文執筆 -> レビュー -> 修正のサイクルを効率的に回す

## 概要

このワークフローでは，レビューごとにGitタグを作成し，前回のタグとの差分を自動計算することで修正箇所を明確化します．
これにより，レビューアーが変更点を把握しやすくなり，レビューの効率化を図ります．

## 基本ワークフロー

### 1. 初期設定

リポジトリをクローンし，作業ディレクトリに移動

```bash
git clone <リポジトリURL>
cd <リポジトリ名>

# 設定ファイル作成
cp config.example config

# 必要に応じて設定を編集（主要なデフォルト値）
# DEFAULT_TARGET=src/main.tex      # ビルド対象ファイル
# DEFAULT_OUT_DIR=out/             # 出力ディレクトリ

# 環境の確認
make validate
```

### 2. 初回バージョンの作成

論文の初稿を完成させ，レビュー用タグを作成

```bash
# LaTeX文書をビルド
make build

# 初回レビュー用タグを作成
git add .
git commit -m "feat: 初稿完成"
git tag -a v1.0.0 -m "Initial version for review"
git push origin v1.0.0
```

### 3. 執筆とコミット

論文の執筆を進め，適宜ビルドとコミット

```bash
# 文書の編集（src/main.tex, src/chapters/*.tex など）

# ビルドして確認
make build

# または自動ビルド
make watch  # ファイル変更を監視して自動ビルド

# コミット
git add .
git commit -m "feat: 序論セクションを追加"
git commit -m "fix: 図表の配置を修正"
```

### 4. レビュー前のバージョン作成

次のレビュー用に新しいタグを作成

```bash
# 最終ビルドと確認
make build

# 全体状況確認
make validate

# レビュー用タグ作成
git tag -a v2.0.0 -m "Second version for review"
git push origin v2.0.0
```

### 5. 差分の確認

差分計算ツールを使用して変更点を確認

```bash
# 全差分生成（PDF、画像、Git差分、メタデータ）
make diff BASE=v1.0.0 CHANGED=v2.0.0

# PDF差分のみ生成
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0

# 画像差分のみ検出
make diff-images BASE=v1.0.0 CHANGED=v2.0.0

# 拡張子別Git差分のみ生成
make diff-ext BASE=v1.0.0 CHANGED=v2.0.0

# オプション引数の指定も可能
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0 TARGET_BASE=src/main.tex TARGET_CHANGED=src/main.tex OUT=custom_output/
```

**引数の説明:**

- `BASE`, `CHANGED`: 必須。比較するGit参照（タグ、ブランチ、コミットハッシュ）
- `TARGET_BASE`, `TARGET_CHANGED`: 省略可能。デフォルトは`config`の`DEFAULT_TARGET`
- `OUT`: 省略可能。デフォルトは`config`の`DEFAULT_OUT_DIR`

**ターゲットファイルパスが異なる場合:**

プロジェクト構造の変更により、比較する両リビジョンで対象ファイルのパスが異なる場合は、明示的に指定してください：

```bash
# 例1: v1.0.0では main.tex、v2.0.0では lualatex-jp-test/main.tex を比較
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0 \
  TARGET_BASE=src/main.tex \
  TARGET_CHANGED=src/lualatex-jp-test/main.tex

# 例2: 旧バージョンが別ディレクトリ構成だった場合
make diff-pdf BASE=v0.9.0 CHANGED=v1.0.0 \
  TARGET_BASE=main.tex \
  TARGET_CHANGED=src/main.tex
```

### 6. レビューと修正

1. 生成されたPDF差分をレビューアーに提供
2. フィードバックに基づいて修正
3. 修正をコミット
4. 必要に応じて新しいタグを作成して差分を再計算

## コミットメッセージ規則

効率的な履歴管理のため，以下の接頭辞を使用:

- `feat:` 新機能・新セクション (マイナーバージョンアップ)
- `fix:` バグ修正・誤字修正 (パッチバージョンアップ)
- `refactor:` コードのリファクタリング (バージョンアップなし)
- `docs:` ドキュメント変更 (バージョンアップなし)
- `style:` 書式・スタイル変更 (バージョンアップなし)
- `BREAKING CHANGE:` 章構造などの破壊的変更 (メジャーバージョンアップ)

## タグ命名規則

- `v1.0.0`, `v2.0.0`: メジャーレビュー版 (章構成の大幅変更等)
- `v1.1.0`, `v1.2.0`: マイナー修正版 (文章の追加・削除など)
- `v1.0.1`, `v1.0.2`: パッチ修正 (誤字修正など)

## 差分確認方法

### テキスト差分（Git）

```bash
git diff v1.0.0 v2.0.0
```

### 視覚的差分（PDF）

```bash
# 差分PDF生成
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0
```

差分計算ツールにより自動生成される`diff_output/diff.pdf`を確認:

- 赤文字・取り消し線: 削除された内容
- 青文字・下線: 追加された内容

## ファイル管理

### 差分出力ファイル

差分生成により以下の構造で出力されます：

```text
out/diff_v1.0.0_to_v2.0.0/
├── metadata.json          # 実行情報とサマリ
├── main-diff.pdf          # PDF差分
├── git_summary.csv        # Git差分サマリ
├── image_summary.csv      # 画像差分サマリ
├── git-diffs/             # 拡張子別差分
│   ├── tex.diff
│   ├── bib.diff
│   └── sty.diff
├── images/                # 画像差分
│   ├── added/             # 追加画像
│   ├── deleted/           # 削除画像
│   └── modified/          # 変更画像
└── logs/                  # 実行ログ
    ├── git.log
    ├── images.log
    └── pdf.log
```

### バックアップとアーカイブ

重要なバージョンは以下のようにアーカイブ:

```bash
# 特定バージョンのアーカイブ作成
git archive --format=zip --output=paper_v2.0.0.zip v2.0.0

# 差分PDFのアーカイブ
cp out/diff_v1.0.0_to_v2.0.0/main-diff.pdf archive/diff_v1.0.0_to_v2.0.0.pdf
```

## 利用可能なコマンド一覧

### 基本機能

- `make build` - LaTeX文書をビルド
    - デフォルトターゲット: `config`の`DEFAULT_TARGET`（通常`src/main.tex`）
    - オプション: `TARGET=src/other.tex`で特定ファイル指定
- `make build-safe` - バリデーション付きビルド
- `make watch` - ファイル変更を監視して自動ビルド
- `make clean` - 出力ファイルをクリーンアップ

### 差分機能

**必須引数**: `BASE=<git参照>` `CHANGED=<git参照>`

- `make diff BASE=tag1 CHANGED=tag2` - 全差分生成（PDF、画像、Git差分、メタデータ）
- `make diff-pdf BASE=tag1 CHANGED=tag2` - PDF差分のみ生成
- `make diff-images BASE=tag1 CHANGED=tag2` - 画像差分のみ検出
- `make diff-ext BASE=tag1 CHANGED=tag2` - 拡張子別Git差分のみ生成

**省略可能な引数**:

- `TARGET_BASE=<TeXファイル>` `TARGET_CHANGED=<TeXファイル>` - 比較対象ファイル（デフォルト: `DEFAULT_TARGET`）
- `OUT=<出力ディレクトリ>` - 出力先（デフォルト: `DEFAULT_OUT_DIR`）

### バリデーション機能

- `make validate` - 全体の状態確認（Git、LaTeX、タグ）
- `make validate-git` - Git状態確認
- `make validate-latex` - LaTeXファイル確認
    - オプション: `TARGET=src/other.tex`で特定ファイル指定
- `make validate-tags` - タグ重複確認
    - オプション: `TAG=v2.0`で特定タグ確認

### その他

- `make help` - 利用可能なコマンド一覧表示
- `make add-tag` - 対話式でタグを作成

### 使用例

```bash
# 基本的なビルド
make build                                    # デフォルトターゲット（config の DEFAULT_TARGET）
make build TARGET=src/lualatex-jp-test/main.tex  # 特定ターゲット

# 差分生成
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0     # 基本的な差分PDF
make diff BASE=HEAD~1 CHANGED=HEAD           # 直前のコミットとの差分
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0 TARGET_BASE=src/main.tex TARGET_CHANGED=src/main.tex OUT=review_output/

# バリデーション
make validate                                 # 全体確認
make validate-latex TARGET=src/pdflatex-test/main.tex  # 特定ターゲットの確認
make validate-tags TAG=v2.0.0               # 特定タグの重複確認
```

詳細な設定方法は [`Configuration_Examples.md`](Configuration_Examples.md) を参照してください．

## 大容量画像ファイルの管理（オプション）

大容量の画像ファイルがある場合は、DVCを使用して管理できます：

```bash
# DVC初期化
dvc init

# リモートストレージ設定
dvc remote add -d storage ssh://user@server/path

# 大容量画像の管理
dvc add src/figures/large_image.png
dvc push

# 他の環境での取得
dvc pull
```

詳細は[DVC公式ドキュメント](https://dvc.org/doc)を参照してください。

## 関連ドキュメント

- **設定とカスタマイズ**: [`Configuration_Examples.md`](Configuration_Examples.md) - 様々な環境での設定例
- **差分ツール詳細**: [`README_DiffTool.md`](README_DiffTool.md) - 差分計算ツールの詳細仕様
