# LaTeX論文執筆環境Dev Containerテンプレート

## 🚀 クイックスタート

**すぐに論文執筆を開始したい場合は [`QUICK_START.md`](QUICK_START.md) を参照してください.**

## 注意

このリポジトリで作成されるコンテナのイメージサイズは8GBを超える重量級です.
パッケージの要否がわかる場合は, `.devcontainer/devcontainer.json`の`postCreateCommand`を編集して不要なパッケージを削除してください.

また本リポジトリのドキュメント・スクリプトの大部分はAIによって生成されています．
本リポジトリの利用により生じた問題については一切の責任を負いませんので，あらかじめご了承ください．

本リポジトリで示しているワークフローや設定例はあくまで参考とし，利用者自身の責任で適切にカスタマイズしてご利用ください．

## 概要

LaTeX論文執筆環境です. 差分表示やDVC画像管理などの支援ツールを段階的に利用できます.

**コンテナの詳細な使用方法・環境設定は [`.devcontainer/README.md`](.devcontainer/README.md) を参照してください.**

[`.devcontainer/README.md`](.devcontainer/README.md)には特に, VS CodeとDev Containerを使用したLaTeX論文執筆環境のセットアップ方法が記載されているため, **目を通しておくことをおすすめします.**

**差分表示等の支援ツールの使用方法は [`docs/workflow.md`](docs/workflow.md) を参照してください.**

**DVC画像管理の詳細な使用方法は [`docs/DVC_Workflow.md`](docs/DVC_Workflow.md) を参照してください.**

## 主な特徴

* **論文執筆環境**: TeX Live 2023, LuaLaTeX, upLaTeX, pdfLaTeX等をサポート
* **差分表示**: `latexdiff`を使用した視覚的な差分表示
* **DVC画像管理**: 大容量画像ファイルの効率
* **段階的機能**: 必要に応じて差分表示・DVC管理を追加

## 段階的な使い方ガイド

### Step 1: とりあえず論文を書く

基本的な論文執筆のみを行う場合:

```bash
# 必須: 設定ファイル作成
cp latex.config.example latex.config
# DVC不使用の場合: DVC_REMOTE_URL等を空白のままにする

# コマンド例
# LaTeX文書ビルド
make build

# 自動ビルド（ファイル変更監視）
make watch
```

VS Codeのコマンドパレットからもビルド可能. 詳細は [`.devcontainer/README.md`](.devcontainer/README.md) を参照してください.

**注意**: DVC機能を使わない場合は, `latex.config`でDVC_REMOTE_URLを空白のままにしてください.

### Step 2: 差分表示を使う

論文の変更箇所を視覚的に確認したい場合:

```bash
# 差分PDF生成（直前の変更を表示）
make diff

# 特定バージョン間の差分
make diff-pdf BASE=v1.0.0 CHANGED=HEAD
```

各種コマンド等の利用例は [`docs/workflow.md`](docs/workflow.md)を参照してください.
またコマンドの詳細は [`docs/README_DiffTool.md`](docs/README_DiffTool.md)を参照してください.

### Step 3: DVC画像管理を使う

大容量画像ファイルを効率的に管理したい場合:

```bash
# latex.configでDVC設定を有効化
# DVC関連設定（例）
# DVC_REMOTE_NAME=storage
# DVC_REMOTE_URL=ssh://user@server/path

# DVC初期化
make dvc-init

# リモートストレージ設定
make dvc-remote-add NAME=storage URL=ssh://user@server/path

# 画像管理開始
make dvc-add-images
make dvc-push
```

詳細はかならず[`docs/DVC_Workflow.md`](docs/DVC_Workflow.md) を参照してください.

## 環境構成

* **LaTeX**: LuaLaTeX, upLaTeX, pdfLaTeX等（各種学会テンプレート対応）
* **参考文献**: BibTeX, Biber
* **支援ツール**: 差分表示（latexdiff）, DVC画像管理（オプション）
* **開発環境**: VS Code + LaTeX Workshop

### 現在の設定について

**この設定はRobot Safety Lab（RSL）の卒業論文向けに最適化されています:**

* `RSL_style.sty`: RSL卒論用のスタイル設定（LuaLaTeX専用）
* フォント: Times系 + BIZ UDフォント（ユニバーサルデザイン）
* 文書構造: 章立て構成（ltjsbook使用）

他の用途で使用する場合は, 該当するスタイルファイルに変更してください.

## 論文執筆の始め方

1. このリポジトリをテンプレートとして使用して新しいリポジトリを作成
2. VS Codeで開き, Dev Container環境を起動
3. 論文執筆開始

```bash
# コマンド一覧確認
make help

# 基本的な論文執筆
make build      # LaTeX文書をビルド
make watch      # ファイル変更を監視して自動ビルド

# 必要に応じて追加機能を利用
make diff       # 差分表示
make dvc-init   # DVC画像管理
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
LICENSE             # 自身の論文に対応したライセンスに差し替えor削除
```

### 保持すべきファイル

以下は論文執筆に必要なため保持してください:

```text
main.tex                    # メイン文書 (RSL卒論用)
RSL_style.sty               # スタイルファイル (RSL卒論用)
chapters/title.tex          # タイトルページ
chapters/chapter1.tex       # 章テンプレート
bibliography/reference.bib  # 参考文献
.devcontainer/              # 開発環境設定
.latexmkrc                  # LaTeXビルド設定
.latexindent.yaml           # LaTeX自動整形設定
Makefile                    # ビルド・差分管理コマンド
scripts/                    # 支援スクリプト
docs/                       # ワークフロー・ツール説明
.github/                    # GitHub設定
.gitignore                  # Git除外設定
.gitattributes              # Git属性設定
.dvcignore                  # DVC除外設定（DVC使用時）
.dvc-exclude                # DVC除外設定（DVC使用時）
latex.config                # LaTeX設定ファイル
latex.config.example        # LaTeX設定ファイルテンプレート
QUICK_START.md              # クイックスタートガイド
```

## 支援ツール

* Pandoc (文書変換)
* GitHub Copilot (文章改善支援)
* LTeX (文法チェック)
* latexdiff (差分表示)
* DVC (画像管理, オプション)

## 搭載機能

* **基本機能**: LaTeX文書ビルド, 自動ビルド
* **差分表示**: latexdiffを使用した視覚的差分表示
* **画像管理**: DVCによる大容量画像ファイル管理（オプション）

## 詳細情報とガイド

基本的な論文執筆環境の詳細は [`.devcontainer/README.md`](.devcontainer/README.md) を参照してください.

段階的な機能利用については以下を参照:

* **基本執筆**: このREADMEの「段階的な使い方ガイド Step 1」，あるいは [`QUICK_START.md`](QUICK_START.md)
* **差分表示**: [`docs/workflow.md`](docs/workflow.md) や [`docs/README_DiffTool.md`](docs/README_DiffTool.md)
* **DVC画像管理**: [`docs/DVC_Workflow.md`](docs/DVC_Workflow.md) - DVCを使用するかの判断基準と詳細手順
* **設定カスタマイズ**: [`docs/Configuration_Examples.md`](docs/Configuration_Examples.md)
* **スクリプト仕様**: [`scripts/README.md`](scripts/README.md)
