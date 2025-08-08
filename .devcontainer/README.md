# LaTeX Development Container 使用方法

この開発環境は, 複数のLaTeXエンジンに対応した高品質な論文執筆のためのDev Container環境です.

**現在の設定**: Robot Safety Lab（RSL）卒業論文向けに最適化されています.

## 前提条件

* **Visual Studio Code**
* **VS Code拡張機能:** Dev Containers
* **Docker Desktop** または互換性のあるコンテナエンジン

### Git over SSH の設定

SSH経由でGitリポジトリを操作する場合は, ホストマシンで以下を完了してください:

* `ssh-agent`の起動
* `ssh-add`でSSHキーの登録

これによりホストマシンのssh設定が自動的にコンテナに引き継がれます（VS CodeのDev Containers機能）．

## セットアップ

### ステップ1. コンテナの起動

1. VS Codeでワークスペースを開く
2. コマンドパレット(`Ctrl+Shift+P` / `Cmd+Shift+P`)から`Dev Containers: Reopen in Container`を実行
3. 初回起動時は必要なパッケージの自動インストールが行われる

### ステップ2. (任意) 外部ディレクトリのマウント

データセットなどをマウントする場合:

1. `.env.example`を`.env`にコピー
2. `ANY_PATH`を目的のディレクトリパスに変更 (変数名も適宜変更)
3. `.devcontainer/devcontainer.json`の`mounts`セクションを更新

```json
// 例: ANY_PATHを/mnt/any_pathにマウントする
"mounts": [
    "source=${localEnv:ANY_PATH},target=/mnt/any_path,type=bind,consistency=cached"
]
```

## LaTeX文書の作成

### タイプセット方法

1. **自動ビルド**: ファイル保存時に自動実行(デフォルト)
2. **手動ビルド**:
    * コマンドパレットから行う場合
        * コマンドパレット(`ctrl+shift+p`)から`LaTeX Workshop: Build with recipe`を選択
        * 適当なレシピを選択してビルド
    * LaTeX Workshop拡張機能のタブ(デフォルトで左側の柱のアイコン)から
        * `Build LaTeX project`を展開
        * 任意のレシピを選択してビルド
3. **PDFプレビュー**: VS Code内のタブで表示

### 使用エンジンとスタイル

* **対応エンジン**: LuaLaTeX, upLaTeX, pdfLaTeX, XeLaTeX等
* **現在のデフォルト**: LuaLaTeX（RSL卒論用）
* **スタイルファイル**: `RSL_style.sty`（Robot Safety Lab卒論専用）

### エンジン変更方法

他の学会テンプレートを使用する場合:

#### ステップ1: devcontainer.jsonの設定変更

`.devcontainer/devcontainer.json`の以下の設定を変更:

```json
// upLaTeX使用の場合
"latex-workshop.latex.tools": [
    {
        "name": "uplatex",
        "command": "uplatex",
        "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
        ]
    },
    {
        "name": "dvipdfmx",
        "command": "dvipdfmx",
        "args": ["%DOCFILE%"]
    }
    ],
    "latex-workshop.latex.recipes": [
    // "latex-workshop.latex.autoBuild.run": "onSave"で使用されるデフォルトレシピは先頭に記述する
    {
        "name": "upLaTeX: uplatex -> dvipdfmx",
        "tools": ["uplatex", "dvipdfmx"]
    },
    // 他のレシピも必要に応じて追加
    {
        "name": "upLaTeX - full",
        "tools": ["uplatex", "bibtex", "uplatex", "dvipdfmx"]
    }
    ],
"latex-workshop.latex.recipe.default": "upLaTeX: uplatex -> dvipdfmx"
```

```json
// pdfLaTeX使用の場合
"latex-workshop.latex.tools": [
    {
        "name": "pdflatex",
        "command": "pdflatex",
        "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
        ]
    }
],
"latex-workshop.latex.recipes": [
    // "latex-workshop.latex.autoBuild.run": "onSave"で使用されるデフォルトレシピは先頭に記述する
    {
        "name": "pdfLaTeX",
        "tools": ["pdflatex"]
    },
    // 他のレシピも必要に応じて追加
    {
        "name": "pdfLaTeX - full",
        "tools": ["pdflatex", "bibtex", "pdflatex", "pdflatex"]
  }
],
"latex-workshop.latex.recipe.default": "pdfLaTeX"
```

#### ステップ2: コンテナの再ビルド

1. コマンドパレット(`Ctrl+Shift+P`)を開く
2. `Dev Containers: Rebuild Container`を実行
3. コンテナが再ビルドされるまで待機

#### ステップ3: スタイルファイルとmain.texの変更

1. `RSL_style.sty`を削除または学会指定のスタイルファイルに置き換え
2. `main.tex`のドキュメントクラスを変更
3. 必要に応じてパッケージ設定を調整

### ビルドレシピ

* **LuaLaTeX一時ビルド**: `lualatex`のみ（デフォルト・RSL用）
* **LuaLaTeX完全ビルド**: `lualatex → bibtex → lualatex × 2`
* **他エンジン**: VS Code設定から変更可能（upLaTeX, pdfLaTeX等）

### ファイル構成

```text
├── main.tex              # メインファイル（RSL卒論用設定）
├── RSL_style.sty         # Robot Safety Lab専用スタイル
├── chapters/             # 章ファイル
│   ├── title.tex         # タイトルページ
│   └── chapter1.tex      # 各章
├── bibliography/         # 参考文献
│   └── reference.bib     # BibTeXファイル
└── figures/              # 図表
```

## 文書変換(Pandoc)

LaTeX文書を他の形式に変換可能:

```bash
# Markdownに変換
pandoc main.tex -o output.md

# HTMLに変換
pandoc main.tex -o output.html --standalone

# Word形式に変換
pandoc main.tex -o output.docx
```

## 環境詳細

### インストール済みパッケージ

* TeX Live 2023 full（全エンジン対応）
* 日本語フォント: Noto CJK, BIZ UD明朝・ゴシック（RSL用）
* Pandoc, latexdiff, chktex

### VS Code拡張機能

* **LaTeX Workshop**: コンパイル・プレビュー（全エンジン対応）
* **LTeX**: 文法・スペルチェック（日本語対応）
* **Pandoc**: 文書変換サポート
* **GitHub Copilot**: 文章改善支援

### 自動クリーンアップ

ビルド成功時に以下のファイルを自動削除:

* `*.aux`, `*.bbl`, `*.blg`, `*.log`など

## トラブルシューティング

### ビルドエラーの場合

1. VS Codeの問題パネルでエラー確認
2. 手動で`latexmk -c`実行
3. コンテナの再起動

### エンジン変更時の注意

* **upLaTeX使用時**:
    * `RSL_style.sty`は使用不可（LuaLaTeX専用）
    * `\usepackage[uplatex]{otf}`等のupLaTeX用パッケージが必要
    * DVI経由でPDF生成（uplatex → dvipdfmx）

* **pdfLaTeX使用時**:
    * 日本語処理が制限される
    * 欧文論文や一部の国際学会向け
    * 直接PDF生成

* **学会テンプレート使用時**:
    * 該当するクラスファイル（.cls）とスタイルファイル（.sty）に変更
    * 学会指定のタイプセット手順に従う

### 代表的な学会テンプレート例

#### IEEE (pdfLaTeX)

```json
"latex-workshop.latex.recipe.default": "pdfLaTeX"
```

`main.tex`: `\documentclass[conference]{IEEEtran}`

#### 日本機械学会 (upLaTeX)

```json
"latex-workshop.latex.recipe.default": "upLaTeX: uplatex -> dvipdfmx"
```

`main.tex`: `\documentclass{jsme}`

#### ACM (pdfLaTeX)

```json
"latex-workshop.latex.recipe.default": "pdfLaTeX"
```

`main.tex`: `\documentclass[sigconf]{acmart}`

### RSL以外での使用

* `RSL_style.sty`を削除または置き換え
* `main.tex`のドキュメントクラスを変更
* 必要に応じてフォント設定を調整

### RSL卒論での使用（デフォルト設定）

現在の設定をそのまま使用:

1. `main.tex`を編集
2. `chapters/`内にコンテンツを追加
3. `bibliography/reference.bib`に参考文献を記載
4. ファイル保存で自動ビルド実行
