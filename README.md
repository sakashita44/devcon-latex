# LaTeX論文テンプレート

注意: このリポジトリで作成されるコンテナのイメージサイズは8GBを超える重量級です．
パッケージの要否がわかる場合は，`.devcontainer/devcontainer.json`の`postCreateCommand`を編集して不要なパッケージを削除してください．

LaTeXを使用した日本語論文執筆のためのテンプレートリポジトリです.

**詳細な使用方法・環境設定は [`.devcontainer/README.md`](.devcontainer/README.md) を参照してください.**

## このテンプレートについて

このリポジトリは, VS CodeとDev Containerを使用してLaTeX論文を執筆するためのテンプレートです. 設定済みの環境で日本語論文を作成できます.

## 環境概要

* **対応エンジン**: LuaLaTeX, upLaTeX, pdfLaTeX等（各種学会テンプレート対応）
* **参考文献**: BibTeX
* **開発環境**: VS Code + LaTeX Workshop

### 現在の設定について

**この設定はRobot Safety Lab（RSL）の卒業論文向けに最適化されています:**

* `RSL_style.sty`: RSL卒論用のスタイル設定（LuaLaTeX専用）
* フォント: Times系 + BIZ UDフォント（ユニバーサルデザイン）
* 文書構造: 章立て構成（ltjsbook使用）

他の用途で使用する場合は、該当するスタイルファイルに変更してください.

## クイックスタート

1. このリポジトリをテンプレートとして使用して新しいリポジトリを作成
2. VS Codeで開き, Dev Container環境を起動
3. 論文執筆開始

```bash
# 基本的な使用方法
make help       # 利用可能なコマンド一覧
make build      # LaTeX文書をビルド
make watch      # ファイル変更を監視して自動ビルド
make diff-pdf BASE=v1.0.0 CHANGED=HEAD  # 差分PDF生成
```

## 他のテンプレートを使用する場合

RSL以外のテンプレートを使用する場合は, エンジンとスタイルファイルの変更が必要です.
**具体的な手順は [`.devcontainer/README.md`](.devcontainer/README.md) の「エンジン変更方法」を参照してください.**

## テンプレート使用時の整理

### 削除推奨ファイル

論文執筆開始前に以下のファイルを削除してください:

```text
sample.tex          # articleサンプル文書
chapters/test.tex   # テストチャプター
figures/test/       # テスト画像フォルダ
README.md           # このファイル (独自内容に置き換え)
```

### 保持すべきファイル

以下は論文執筆に必要なため保持してください:

```text
main.tex                    # メイン文書
RSL_style.sty               # スタイルファイル (RSL卒論用)
chapters/title.tex          # タイトルページ
chapters/chapter1.tex       # 章テンプレート
bibliography/reference.bib  # 参考文献
.devcontainer/              # 開発環境設定
.latexmkrc                  # LaTeXビルド設定
Makefile                    # ビルド・差分管理コマンド
scripts/                    # 差分PDF生成スクリプト
docs/                       # ワークフロー・ツール説明
.github/                    # GitHub設定
```

## サポートツール

* Pandoc (文書変換)
* GitHub Copilot (文章改善支援)
* LTeX (文法チェック)
* Git差分表示ワークフロー

## 主な機能

* **LaTeX文書ビルド**: `make build`, `make watch`
* **差分PDF生成**: latexdiffを使用した視覚的差分表示
* **Git統合**: バージョン間差分の自動計算
* **日本語対応**: LuaLaTeX + BIZ UDフォント

詳細な機能説明・設定方法・トラブルシューティングは [`.devcontainer/README.md`](.devcontainer/README.md) を参照してください.

また，差分PDF生成等については[`docs/workflow.md`](docs/workflow.md) や [`docs/README_DiffTool.md`](docs/README_DiffTool.md) を参照してください.
