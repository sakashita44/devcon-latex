# LaTeX論文テンプレート

LuaLaTeX + BIZ UDフォントを使用した日本語論文執筆のためのテンプレートリポジトリです.

詳細な使用方法は [**`.devcontainer/README.md`**](.devcontainer/README.md) を参照してください.

## このテンプレートについて

このリポジトリは, VS CodeとDev Containerを使用してLaTeX論文を執筆するためのテンプレートです. 設定済みの環境で日本語論文を作成できます.

## 使用開始方法

1. このリポジトリをテンプレートとして使用して新しいリポジトリを作成
2. VS Codeで開き, Dev Container環境を起動
3. **詳細な使用方法・環境設定は [`.devcontainer/README.md`](.devcontainer/README.md) を参照**

## 他の学会テンプレートを使用する場合

RSL以外の学会テンプレートを使用する場合は, エンジンとスタイルファイルの変更が必要です.
**具体的な手順は [`.devcontainer/README.md`](.devcontainer/README.md) の「エンジン変更方法」を参照してください.**

## テンプレート使用時の削除推奨ファイル

論文執筆を開始する前に, 以下のサンプルファイルを削除することを推奨します:

### サンプルファイル (削除推奨)

```text
sample.tex          # articleサンプル文書
sample.pdf          # サンプルPDF
sample.synctex.gz   # サンプル同期ファイル
chapters/test.tex   # テスト用章
figures/test/       # テストフォルダ全体
```

### このREADME

このREADME自体もテンプレート説明のため, 削除して独自の内容に置き換えてください.

## 保持すべきファイル

以下のファイルは論文執筆に必要なため保持してください(RSL卒論時):

```text
main.tex                    # メイン文書
RSL_style.sty               # スタイルファイル
chapters/title.tex          # タイトルページ
chapters/chapter1.tex       # 章テンプレート
bibliography/reference.bib  # 参考文献
.devcontainer/              # 開発環境設定
.github/                    # GitHub設定
docs/workflow.md            # Git運用説明
```

## 環境概要

* **対応エンジン**: LuaLaTeX, upLaTeX, pdfLaTeX等（各種学会テンプレート対応）
* **参考文献**: BibTeX
* **開発環境**: VS Code + LaTeX Workshop

### 現在の設定について

**この設定はRobot Safety Lab（RSL）の卒業論文向けに最適化されています:**

* `RSL_style.sty`: RSL卒論用のスタイル設定（LuaLaTeX専用）
* フォント: Times系 + BIZ UDフォント（ユニバーサルデザイン）
* 文書構造: 章立て構成（ltjsbook使用）

他の学会・用途で使用する場合は、該当するスタイルファイルに変更してください.

## サポートツール

* Pandoc (文書変換)
* GitHub Copilot (文章改善支援)
* LTeX (文法チェック)
* Git差分表示ワークフロー
