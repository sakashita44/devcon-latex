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

* TeX Live 2023フルインストール
    * 追加で日本語フォント(BIZ UD)を導入済み
* VS Code + Dev Containerによる開発環境
    * LaTeX Workshop導入済み
        * セーブ時フォーマット，セーブ時ビルド設定済み
* その他拡張機能: LTeX (文法チェック), Pandoc (文書変換) を搭載
* Git, DVCによるバージョン管理に対応
* 差分可視化ツール搭載
    * latexdiffを含む各種スクリプトの実行を自動化(make経由で実行)

### 日本語卒論用テンプレート

* Robot Safety Labで使用している卒論テンプレートを同梱（`src/`ディレクトリ内に配置）
* 設定ファイル等についても同テンプレートに最適化済み

## 環境構成

* **ベース**: Ubuntu + TeX Live 2023 (scheme-full)
* **エディタ**: VS Code + LaTeX Workshop拡張
* **搭載ツール**: latexdiff, DVC, Pandoc, LTeX拡張, git
* **対応言語**: 日本語(LuaLaTeX), 英語(pdfLaTeX), 他TeX Live対応言語

## 利用開始方法

1. このリポジトリをテンプレートとして使用して新しいリポジトリを作成
2. VS Codeで開き, Dev Container環境を起動
3. 論文執筆開始

```bash
# コマンド一覧確認
make help

# 基本的な論文執筆
make build      # LaTeX文書をビルド（デフォルト: src/main.tex）
make watch      # ファイル変更を監視して自動ビルド

# 必要に応じて追加機能を利用
make diff       # 差分表示
make diff-pdf BASE=tag1 CHANGED=tag2 # タグ間差分をpdf化して表示
```

## 詳細情報とガイド

### 基本的な論文執筆

* **環境セットアップ**: [`.devcontainer/README.md`](.devcontainer/README.md)
* **クイックスタート**: [`QUICK_START.md`](QUICK_START.md)

### 高度な機能

* **差分表示**: [`docs/Workflow.md`](docs/Workflow.md), [`docs/README_DiffTool.md`](docs/README_DiffTool.md)
* **設定カスタマイズ**: [`docs/Configuration_Examples.md`](docs/Configuration_Examples.md)
* **スクリプト仕様**: [`scripts/README.md`](scripts/README.md)

### 他のテンプレート使用時

RSL以外のテンプレートを使用する場合は`.latexmkrc`の適切な書き換えや，設定ファイルの調整が必要になる可能性があります．
