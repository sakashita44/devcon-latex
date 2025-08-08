# LaTeX-Paper-Template

LaTeXを使用した論文執筆のための個人用テンプレート.

## 環境

* Docker Devcontainerを使用したLaTeX環境
* LuaLaTeXエンジンでタイプセット
* VS CodeのLaTeX Workshopによる統合開発環境

## 設定概要

この設定では, `lualatex`を使用してタイプセットしている

* DockerコンテナにはTeX Live 2023が含まれ, 必要なパッケージがプリインストール済み
* 日本語フォントとしてNoto Serif CJK JPを使用
* 欧文フォントとしてLatin Modernを使用

## 主な機能

* LuaLaTeXによる高品質な日本語・英語混在文書の作成
* Pandocによる他形式（Markdown, HTML, DOCX等）への変換
* VS CodeのLaTeX Workshopによるリアルタイムプレビュー
* GitHub Copilotによる文章改善支援

## ファイル構成

```text
├── main.tex              # メインのLaTeXファイル
├── style.sty             # 独自スタイルファイル
├── chapters/             # 章ごとのファイル
├── figures/              # 図表ファイル
├── bibliography/         # 参考文献ファイル
└── docs/                 # ドキュメント
```

## 使用方法

1. VS Codeでワークスペースを開く
2. `main.tex`を編集
3. Ctrl+Alt+B（またはCmd+Option+B）でビルド
4. VS Code内でPDFプレビューを確認

## 文書変換

PandocによりLaTeX文書を他の形式に変換可能:

```bash
# Markdownに変換
pandoc main.tex -o output.md

# HTMLに変換
pandoc main.tex -o output.html --standalone

# Microsoft Word形式に変換
pandoc main.tex -o output.docx
```

## Git運用

指導教員等にレビューしてもらうために, gitのtagを使用した差分表示のワークフローを想定している

* `docs/workflow.md`参照

## カスタマイズ

`main.tex`の以下の設定を必要に応じて修正:

* フォント設定（日本語・欧文）
* ページレイアウト
* ヘッダー・フッターの設定
* 引用スタイル

GitHub Copilotに対して`.github/copilot-instructions.md`を提示して文章改善を促している

## TODO

* latexdiffを使用して差分を表示するスクリプトを追加
* 追加のフォントオプションの提供
* 自動テストとCI/CDの設定
