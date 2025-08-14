# LaTeX論文執筆環境Dev Containerテンプレート

このREADMEはこのテンプレートリポジトリの機能紹介を主目的としています．
必要に応じて，自身の論文等に合わせてカスタマイズして利用してください.

## 🚀 クイックスタート

**すぐに論文執筆を開始したい場合は [`QUICK_START.md`](QUICK_START.md) を参照してください.**

## 注意

このリポジトリで作成されるコンテナのイメージサイズは8GBを超える重量級です.
パッケージの要否がわかる場合は, `.devcontainer/devcontainer.json`の`postCreateCommand`を編集して不要なパッケージを削除してください.

また本リポジトリのドキュメント・スクリプトの大部分はAIによって生成されています．
本リポジトリの利用により生じた問題については一切の責任を負いませんので，あらかじめご了承ください．

本リポジトリで示しているワークフローや設定例はあくまで参考とし，利用者自身の責任で適切にカスタマイズしてご利用ください．

## 概要

VS Code + Dev ContainerベースのLaTeX論文執筆環境です. TeX Live 2023フルインストールにより多様なパッケージが利用でき, 差分表示やDVC画像管理などの機能を段階的に追加できます.

## 主な特徴

### 📝 TeX Live 2023フルインストール環境

* **TeX Live 2023**: フルインストールによる多様なパッケージ・エンジン利用可能
* **エンジン**: LuaLaTeX, upLaTeX, pdfLaTeX等が利用可能
* **外部テンプレート**: 各種学会テンプレートのビルドが可能（テンプレート自体は別途入手が必要）
* **参考文献**: BibTeX, Biberが利用可能
* **フォント**: BIZ UDフォントを含む日本語フォントを搭載

### 🔧 VS Code + Dev Container環境

* **LaTeX Workshop**: VS Code拡張による編集・ビルド環境
* **自動ビルド**: ファイル保存時のPDF自動生成機能
* **拡張機能**: LTeX (文法チェック), Pandoc (文書変換) を搭載
* **GitHub Copilot**: 利用可能（個人のライセンス・設定に依存）

### 📊 論文管理支援機能

* **差分表示**: `latexdiff`を活用した変更箇所の視覚化スクリプトを提供 (`make diff-pdf` コマンド等)
* **バージョン管理**: Gitタグを利用した論文バージョン管理
* **画像ファイル管理**: DVC(Data Version Control)による大容量画像管理（オプション機能）
* **段階的導入**: 基本執筆→差分表示→DVC管理の順で必要に応じて機能追加可能

### 日本語卒論用テンプレート

* Robot Safety Labで使用している卒論テンプレートを同梱 (main.tex, RSL_style.sty, chapters/)
* 設定ファイル等についても同テンプレートに最適化済み

## 環境構成

* **ベース**: Ubuntu + TeX Live 2023 (scheme-full)
* **エディタ**: VS Code + LaTeX Workshop拡張
* **搭載ツール**: latexdiff, DVC, Pandoc, LTeX拡張, git
* **対応言語**: 日本語(LuaLaTeX), 英語(pdfLaTeX), 他TeX Live対応言語

## 段階的な機能利用

このテンプレートでは, 必要に応じて段階的に機能を追加できます:

1. **基本執筆**: LaTeX文書の作成・ビルド
2. **差分表示**: 変更箇所の視覚化
3. **画像管理**: 大容量ファイルのバージョン管理

詳細な使用方法は各種ドキュメントを参照してください.

## 利用開始方法

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
make diff-pdf BASE=tag1 CHANGED=tag2 # タグ間差分をpdf化して表示
make dvc-init   # DVC画像管理
```

## 詳細情報とガイド

### 基本的な論文執筆

* **環境セットアップ**: [`.devcontainer/README.md`](.devcontainer/README.md)
* **クイックスタート**: [`QUICK_START.md`](QUICK_START.md)

### 高度な機能

* **差分表示**: [`docs/Workflow.md`](docs/Workflow.md), [`docs/README_DiffTool.md`](docs/README_DiffTool.md)
* **DVC画像管理**: [`docs/DVC_Workflow.md`](docs/DVC_Workflow.md)
* **設定カスタマイズ**: [`docs/Configuration_Examples.md`](docs/Configuration_Examples.md)
* **スクリプト仕様**: [`scripts/README.md`](scripts/README.md)

### 他のテンプレート使用時

RSL以外のテンプレートを使用する場合は, エンジンとスタイルファイルの変更が必要です.
**具体的な手順は [`.devcontainer/README.md`](.devcontainer/README.md) の「エンジン変更方法」を参照してください.**
