# LaTeX Development Container 使用方法

この開発環境は, 複数のLaTeXエンジンに対応した高品質な論文執筆のためのDev Container環境です.

差分PDFの生成等については [`docs/Workflow.md`](../docs/Workflow.md) や [`docs/README_DiffTool.md`](../docs/README_DiffTool.md) を参照してください.

**初期設定**: Robot Safety Lab（RSL）卒業論文向けに最適化されています.

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

1. `.devcontainer/.env.example`を`.devcontainer/.env`にコピー
2. `ANY_PATH`を目的のディレクトリパスに変更 (変数名も適宜変更)
3. `.devcontainer/devcontainer.json`の`mounts`セクションを更新

**重要**: `.devcontainer/.env`ファイルは、内容が空でもコンテナビルドのために必要です。ファイルが存在しない場合、ビルドエラーが発生します。

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
    * makeコマンドを使用したビルド
        * `make build`を実行（`config`ファイルのデフォルト設定を使用）
        * `make build TARGET=src/paper.tex`のように実行時に対象ファイルを指定可能
    * 変更を検知した場合の自動ビルド
        * `make watch`を実行 (ターミナルを起動したままにしておく必要があります)
        * ファイル変更を監視して自動ビルド
        * `make watch TARGET=src/paper.tex`のように実行時に対象ファイルを指定可能
3. **PDFプレビュー**: VS Code内のタブで表示

### コードフォーマット

* **フォーマッター**: `latexindent`を使用
* **設定ファイル**: `.latexindent.yaml`（カスタマイズ可能）
* **自動フォーマット**: ファイル保存時・ペースト時に自動実行
* **手動フォーマット**: `Shift+Alt+F` / `Shift+Option+F`

フォーマット機能により、表・数式の自動整列、インデント調整、改行位置の統一などが自動的に行われます。

### ビルドエンジン

* **対応エンジン**: LuaLaTeX, upLaTeX, pdfLaTeX, XeLaTeX等
* **設定ファイル**: `.latexmkrc`でエンジンやビルド方法を設定
* **デフォルト**: LuaLaTeX（RSL卒論用）

**注意**: エンジン変更は`.latexmkrc`の設定変更で行います。詳細は [`docs/Configuration_Examples.md`](../docs/Configuration_Examples.md) を参照してください。

### 設定ファイル

プロジェクトの設定は`config`ファイルで管理できます：

```bash
# config.exampleをコピーして設定
cp config.example config

# 設定例
DEFAULT_TARGET=src/main.tex    # ビルド対象のメインファイル
DEFAULT_OUT_DIR=out/           # 出力ディレクトリ
```

詳細な設定方法は [`docs/Configuration_Examples.md`](../docs/Configuration_Examples.md) を参照してください.

## 文書変換(Pandoc)

LaTeX文書を他の形式に変換可能:

```bash
# Markdownに変換
pandoc src/main.tex -o output.md

# HTMLに変換
pandoc src/main.tex -o output.html --standalone

# Word形式に変換
pandoc src/main.tex -o output.docx
```

## 環境詳細

### インストール済みパッケージ

* **TeX Live 2023 full**（ベースイメージに含まれる・全エンジン対応）
* **追加インストール**:
    * Pandoc（文書変換）
    * Noto CJK fonts（汎用日本語フォント）
    * BIZ UD fonts（RSL用・ユニバーサルデザインフォント）
    * locales（日本語ロケール設定）

### VS Code拡張機能

* **LaTeX Workshop**: コンパイル・プレビュー（全エンジン対応）
    * 自動フォーマット: `latexindent`（保存時・ペースト時）
    * 設定ファイル: `.latexindent.yaml`
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

### RSL以外での使用

他のテンプレートや学会フォーマットを使用する場合：

* `.latexmkrc`でビルドエンジンを変更
* `config`ファイルでデフォルトのビルド対象を変更
* 必要に応じてスタイルファイルやドキュメントクラスを置き換え

詳細は [`docs/Configuration_Examples.md`](../docs/Configuration_Examples.md) を参照してください。

### RSL卒論での使用（デフォルト設定）

現在の設定をそのまま使用:

1. `src/main.tex`を編集
2. `src/chapters/`内にコンテンツを追加
3. `src/bibliography/reference.bib`に参考文献を記載
4. ファイル保存で自動ビルド実行
