# LaTeX Development Container 使用方法

この開発環境は, LuaLaTeX + BIZ UDフォントを使用した高品質な日本語論文執筆のためのDev Container環境です.

## 前提条件

* **Visual Studio Code**
* **VS Code拡張機能:** Dev Containers
* **Docker Desktop** または互換性のあるコンテナエンジン

### Git over SSH の設定

SSH経由でGitリポジトリを操作する場合は, ホストマシンで以下を完了してください:

* `ssh-agent`の起動
* `ssh-add`でSSHキーの登録

## セットアップ

### ステップ1. コンテナの起動

1. VS Codeでワークスペースを開く
2. コマンドパレット(`Ctrl+Shift+P` / `Cmd+Shift+P`)から`Dev Containers: Reopen in Container`を実行
3. 初回起動時は必要なパッケージの自動インストールが行われる

### ステップ2. (任意) 外部ディレクトリのマウント

データセットなどをマウントする場合:

1. `.env.example`を`.env`にコピー
2. `ANY_PATH`を目的のディレクトリパスに変更

## LaTeX文書の作成

### タイプセット方法

1. **自動ビルド**: ファイル保存時に自動実行(デフォルト)
2. **手動ビルド**: `Ctrl+Alt+B` / `Cmd+Option+B`
3. **PDFプレビュー**: VS Code内のタブで表示

### 使用エンジンとフォント

* **タイプセットエンジン**: LuaLaTeX
* **日本語フォント**: BIZ UD明朝・ゴシック(Morisawa製)
* **欧文フォント**: Latin Modern

### ビルドレシピ

* **一時ビルド**: `lualatex`のみ(デフォルト)
* **完全ビルド**: `lualatex → bibtex → lualatex × 2`

### ファイル構成

```text
├── main.tex              # メインファイル
├── RSL_style.sty         # スタイル設定
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

* TeX Live 2023 full
* 日本語フォント: Noto CJK, BIZ UD明朝・ゴシック
* Pandoc, latexdiff, chktex

### VS Code拡張機能

* **LaTeX Workshop**: コンパイル・プレビュー
* **LTeX**: 文法・スペルチェック(日本語対応)
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

### フォントエラーの場合

* BIZ UDフォントが正しくインストールされているか確認
* 必要に応じて`fc-cache -fv`実行
