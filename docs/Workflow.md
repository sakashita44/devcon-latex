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
cp latex.config.example latex.config

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
# 文書の編集（main.tex, chapters/*.tex など）

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
# 自動差分計算（直前の変更を表示）
make diff

# 特定バージョン間の差分
make diff-pdf BASE=v1.0.0 CHANGED=v2.0.0
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

- `diff_output/git_diff.txt`: Git差分（テキスト形式）
- `diff_output/diff.tex`: LaTeX差分ファイル
- `diff_output/diff.pdf`: 視覚的差分PDF

### バックアップとアーカイブ

重要なバージョンは以下のようにアーカイブ:

```bash
# 特定バージョンのアーカイブ作成
git archive --format=zip --output=paper_v2.0.0.zip v2.0.0

# 差分PDFのアーカイブ
cp diff_output/diff.pdf archive/diff_v1.0.0_to_v2.0.0.pdf
```

## 利用可能なコマンド一覧

### 基本機能

- `make build` - LaTeX文書をビルド
- `make watch` - ファイル変更を監視して自動ビルド
- `make clean` - 出力ファイルをクリーンアップ
- `make validate` - 全体の状態確認

### 差分機能

- `make diff` - 直前の変更を差分表示
- `make diff-pdf BASE=tag1 CHANGED=tag2` - 指定バージョン間の差分PDF生成

### その他

- `make help` - 利用可能なコマンド一覧表示

詳細な設定方法は [`Configuration_Examples.md`](Configuration_Examples.md) を参照してください．

## 関連ドキュメント

- **設定とカスタマイズ**: [`Configuration_Examples.md`](Configuration_Examples.md) - 様々な環境での設定例
- **DVC画像管理**: [`DVC_Workflow.md`](DVC_Workflow.md) - 大容量画像ファイルがある場合の発展形ワークフロー
- **差分ツール詳細**: [`README_DiffTool.md`](README_DiffTool.md) - 差分計算ツールの詳細仕様
