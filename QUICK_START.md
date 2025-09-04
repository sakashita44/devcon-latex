# クイックスタートガイド

すぐに論文執筆を開始したい人向けのガイド

## 🚀 クイックスタート

このガイドはVS CodeとDev Containerを使用してLaTeX論文執筆を始めるための簡単な手順を提供します．以下のチェックリストに従って必要な準備を行い，論文執筆を開始してください．

### ✅ 事前準備チェックリスト

- [ ] VS Codeをインストール済み
- [ ] VS Codeの拡張機能「Dev Containers」をインストール済み
- [ ] Dockerをインストール済み（Docker Desktopなど）
- [ ] `.devcontainer/.env`ファイルが存在する（`.devcontainer/.env.example`をコピー。内容が空でも必要）

**重要**: `.devcontainer/.env`ファイルはコンテナビルドに必要です。このファイルが存在しない場合、初回起動時にエラーが発生します。

### ✅ 論文執筆開始チェックリスト

#### Step 1: 環境起動（初回のみ）

- [ ] このリポジトリをクローンまたはテンプレートとして使用
- [ ] VS Codeで開く
- [ ] 右下に表示される「Reopen in Container」をクリック
- [ ] コンテナ起動完了まで待機

#### Step 2: 基本設定（初回のみ）

- [ ] `config.example`をもとに設定ファイルを作成：`cp config.example config`
- [ ] 不要なファイルを削除 (詳細は [テンプレート使用時の整理](#テンプレート使用時の整理) を参照)
- [ ] git configのsafe.directoryを設定: `git config --global --add safe.directory /workspaces`

#### Step 3: 論文執筆開始

- [ ] `src/main.tex`を開いて執筆開始
- [ ] ファイル保存で自動ビルドが実行されることを確認
- [ ] 生成されたPDFが`out/`ディレクトリに出力されることを確認
- [ ] `src/chapters/chapter1.tex`を編集して論文を書き始める

#### Step 4: ビルド確認

- [ ] 左側のTEXマークをクリックし, 「Full」レシピを選択してビルド実行
- [ ] または, `Ctrl+Shift+P` → 「LaTeX Workshop: Build LaTeX project」でビルド実行
- [ ] エラーなくPDFが生成されることを確認
- [ ] 日本語が正しく表示されることを確認

### 🔧 トラブルシューティング

#### ✅ ビルドエラーが発生した場合

- [ ] VS Code設定で「latex-workshop.latex.recipe.default」が「latexmk」になっているか確認
- [ ] `src/.latexmkrc`ファイルの設定が正しいか確認
- [ ] `config`ファイルが存在するか確認
- [ ] `config`内の`DEFAULT_TARGET=src/main.tex`が正しいか確認

#### ✅ コンテナビルドエラーが発生した場合

- [ ] `.devcontainer/.env`ファイルが存在するか確認
- [ ] `.devcontainer/.env`ファイルが存在しない場合：`cp .devcontainer/.env.example .devcontainer/.env`でコピー
- [ ] パスの文字エンコーディングや特殊文字に問題がないか確認
- [ ] Docker Desktopが正常に動作しているか確認

#### ✅ ファイル構造エラーが発生した場合

- [ ] `src/main.tex`ファイルが存在するか確認
- [ ] `src/RSL_style.sty`ファイルが存在するか確認
- [ ] `src/chapters/`フォルダが存在するか確認
- [ ] 異なるターゲットの場合, `config`内のパス，あるいはmakeに渡しているパスが正しいか確認

#### ✅ エラーログの確認方法

- [ ] `.log`ファイルを直接開いてエラー内容を確認
- [ ] VS Codeの「Problems」タブでエラー・警告を確認
- [ ] ターミナルでビルド時の出力メッセージを確認
- [ ] エラーの種類に応じて対処:
    - [ ] フォントエラー → LuaLaTeXエンジン設定を確認
    - [ ] ファイル not found → パスとファイル名を確認
    - [ ] 文法エラー → 対象行の構文を確認

### 💡 基本操作ガイド

#### ✅ VS CodeのGUI操作

- [ ] 自動ビルド設定: ファイル保存時に自動でPDFが生成される
- [ ] 手動ビルド実行: 左側のTEXマークをクリック → 適当なレシピを選択
- [ ] コマンドパレット使用: `Ctrl+Shift+P` → 「LaTeX Workshop: Build LaTeX project」

#### ✅ LaTeX Workshopの機能確認

- [ ] サイドバーでLaTeX Workshopアイコンを確認 → 章構造が表示される
- [ ] PDFが自動的に横に表示されることを確認
- [ ] 問題が発生した場合, 下部パネルにエラーが表示されることを確認

#### ✅ 最終版作成時の手順

- [ ] VS Codeのコマンドパレット（`Ctrl+Shift+P`）→「LaTeX Workshop: Build LaTeX project」
- [ ] または, ターミナルで`make build`を実行
- [ ] エラーなく完了することを確認
- [ ] (必要に応じて)一時ファイルのクリーンアップ: `make clean`を実行

## 利用可能な機能

基本的な論文執筆環境の構築が完了したら、以下の機能により執筆作業を効率化できます。

### ビルド機能

**目的**: LaTeX文書の基本的な作成・ビルド

基本的な論文執筆を行う場合：

```bash
# 必須: 設定ファイル作成
cp config.example config

# LaTeX文書ビルド
make build

# 自動ビルド（ファイル変更監視）
make watch

# バリデーション付きビルド
make build-safe

# 出力ファイルのクリーンアップ
make clean
```

### バリデーション機能

**目的**: プロジェクトの状態確認とエラー予防

プロジェクトの状態を確認したい場合：

```bash
# 全体の状態確認（Git、LaTeX、タグ）
make validate

# Git状態確認
make validate-git

# LaTeXファイル確認
make validate-latex

# タグ重複確認
make validate-tags

# 対話式でタグを作成
make add-tag
```

### 差分表示機能

**目的**: 論文の変更箇所を視覚的に確認

論文の変更箇所を視覚的に確認したい場合：

```bash
# 全差分生成（PDF、画像、Git差分、メタデータ）
make diff BASE=v1.0.0 CHANGED=v1.1.0

# PDF差分のみ生成
make diff-pdf BASE=v1.0.0 CHANGED=HEAD

# 画像差分のみ検出
make diff-images BASE=v1.0.0 CHANGED=HEAD

# 拡張子別Git差分のみ生成
make diff-ext BASE=v1.0.0 CHANGED=HEAD
```

各種コマンド等の利用例は [`docs/Workflow.md`](docs/Workflow.md) を参照してください。
またコマンドの詳細は [`docs/README_DiffTool.md`](docs/README_DiffTool.md) を参照してください。

### DVCによるバイナリファイル管理

**目的**: 大容量画像ファイル等のバージョン管理

大容量画像ファイルを効率的に管理したい場合、DVCが使用可能です：

```bash
# DVC初期化
dvc init

# リモートストレージ設定
dvc remote add -d storage ssh://user@server/path

# 画像管理開始
dvc add src/figures/large_image.png
dvc push

# 他の環境での画像取得
dvc pull
```

詳細は[DVC公式ドキュメント](https://dvc.org/doc)を参照してください。

## テンプレート使用時の整理

論文執筆開始前に, テンプレートファイルを整理することを推奨します.

### ファイル整理ガイド

#### 🗑️ 削除推奨ファイル

論文執筆開始前に以下のファイルを削除してください:

| ファイル/フォルダ       | 説明                   | 削除理由                                       |
| ----------------------- | ---------------------- | ---------------------------------------------- |
| `src/sample.tex`        | articleサンプル文書    | サンプルのため不要                             |
| `src/chapters/test.tex` | テストチャプター       | サンプルのため不要                             |
| `src/figures/test/`     | テスト画像フォルダ     | サンプルのため不要                             |
| `README.md`             | リポジトリ概要ファイル | 独自内容に置き換え                             |
| `LICENSE`               | ライセンスファイル     | 自身の論文に対応したライセンスに差し替えor削除 |

#### ✅ 保持必須ファイル

以下のファイルは論文執筆に必要なため**必ず保持**してください:

| カテゴリ         | ファイル/フォルダ   | 説明                          | 備考                                 |
| ---------------- | ------------------- | ----------------------------- | ------------------------------------ |
| **環境設定**     | `.devcontainer/`    | 開発環境設定                  | -                                    |
|                  | `src/.latexmkrc`    | LaTeXビルド設定               | 内容は適宜変更のこと                 |
|                  | `.latexindent.yaml` | LaTeX自動整形設定             | -                                    |
|                  | `config`            | LaTeX設定ファイル             | 作成後                               |
|                  | `config.example`    | LaTeX設定ファイルテンプレート | -                                    |
| **ビルド・管理** | `Makefile`          | ビルド・差分管理コマンド      | -                                    |
|                  | `scripts/`          | 支援スクリプト                | -                                    |
|                  | `docs/`             | ワークフロー・ツール説明      | -                                    |
| **Git・GitHub**  | `.github/`          | GitHub設定                    | 内容は個人の好みに合わせて設定のこと |
|                  | `.gitignore`        | Git除外設定                   | -                                    |
|                  | `.gitattributes`    | Git属性設定                   | -                                    |
| **DVC**          | `.dvcignore`        | DVC除外設定                   | DVC使用時のみ                        |
| **ドキュメント** | `QUICK_START.md`    | クイックスタートガイド        | -                                    |

#### 📝 用途に応じて判断するファイル

以下のファイルはRSL卒論用のため, 他の用途では削除を検討してください:

| ファイル/フォルダ                | 説明                         | RSL卒論以外での判断        |
| -------------------------------- | ---------------------------- | -------------------------- |
| `src/main.tex`                   | メイン文書 (RSL卒論用)       | 他テンプレート使用時は削除 |
| `src/RSL_style.sty`              | スタイルファイル (RSL卒論用) | 他テンプレート使用時は削除 |
| `src/chapters/title.tex`         | タイトルページ               | 他テンプレート使用時は削除 |
| `src/chapters/chapter1.tex`      | 章テンプレート               | 他テンプレート使用時は削除 |
| `src/bibliography/reference.bib` | 参考文献                     | どの用途でも保持推奨       |

### 異なるテンプレート使用時のTips

#### エンジン設定の変更

各テンプレートに応じて `src/.latexmkrc` ファイルのエンジン設定を変更してください：

- [ ] **pdfLaTeX系**: `$pdf_mode = 1; $pdflatex = 'pdflatex %O %S';`
- [ ] **LuaLaTeX系**: `$pdf_mode = 4; $lualatex = 'lualatex %O %S';`
- [ ] **upLaTeX系**: `$pdf_mode = 3; $latex = 'uplatex %O %S';`

#### その他の設定変更

- [ ] `config`の`DEFAULT_TARGET`を該当するメインファイル名に変更
- [ ] `src/RSL_style.sty`を使用しない場合は`src/main.tex`から該当行を削除
- [ ] テンプレート付属のスタイルファイル（`.sty`, `.cls`）を`src/`ディレクトリに配置
- [ ] 日本語フォント設定がテンプレートに含まれているか確認
- [ ] BibTeXスタイル（`.bst`）がテンプレート指定のものか確認

#### 設定変更後の注意事項

- [ ] `src/.latexmkrc`ファイルの設定変更後、コンテナを再起動
- [ ] VS Code設定の「latex-workshop.latex.recipe.default」も変更
- [ ] フォント設定がエンジンに対応しているか確認
