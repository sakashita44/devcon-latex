# クイックスタートガイド

すぐに論文執筆を開始したい人向けのガイド

## 🚀 クイックスタート

このガイドはVS CodeとDev Containerを使用してLaTeX論文執筆を始めるための簡単な手順を提供します．以下のチェックリストに従って必要な準備を行い，論文執筆を開始してください．

### ✅ 事前準備チェックリスト

- [ ] VS Codeをインストール済み
- [ ] VS Codeの拡張機能「Dev Containers」をインストール済み
- [ ] Dockerをインストール済み（Docker Desktopなど）

### ✅ 論文執筆開始チェックリスト

#### Step 1: 環境起動（初回のみ）

- [ ] このリポジトリをクローンまたはテンプレートとして使用
- [ ] VS Codeで開く
- [ ] 右下に表示される「Reopen in Container」をクリック
- [ ] コンテナ起動完了まで待機

#### Step 2: 基本設定（初回のみ）

- [ ] `latex.config.example`をもとに設定ファイルを作成．例: `cp latex.config.example latex.config`
    - DVC機能を使わない場合は`latex.config`内の`DVC_REMOTE_URL`を空白のまま保持
- [ ] 不要なファイルを削除 (詳細は [テンプレート使用時の整理](#テンプレート使用時の整理) を参照)
- [ ] git configのsafe.directoryを設定: `git config --global --add safe.directory /workspaces`

#### Step 3: 論文執筆開始

- [ ] `main.tex`を開いて執筆開始
    - 異なるテンプレートを使用する場合は, `latex.config`内の`MAIN_TEX`等を確認
- [ ] ファイル保存で自動ビルドが実行されることを確認
- [ ] 生成されたPDFが`main.pdf`として出力されることを確認
- [ ] `chapters/chapter1.tex`を編集して論文を書き始める

#### Step 4: ビルド確認

- [ ] 左側のTEXマークをクリックし, 「Full」レシピを選択してビルド実行
- [ ] または, `Ctrl+Shift+P` → 「LaTeX Workshop: Build LaTeX project」でビルド実行
- [ ] エラーなくPDFが生成されることを確認
- [ ] 日本語が正しく表示されることを確認

### 🔧 トラブルシューティング

#### ✅ ビルドエラーが発生した場合

- [ ] VS Code設定で「latex-workshop.latex.recipe.default」が「lualatex」になっているか確認
- [ ] `.latexmkrc`ファイルの`$latex`が`lualatex`になっているか確認
- [ ] `latex.config`ファイルが存在するか確認
- [ ] `latex.config`内の`MAIN_TEX=main.tex`が正しいか確認
- [ ] `latex.config`内の`LATEX_ENGINE=lualatex`が正しいか確認

#### ✅ ファイル構造エラーが発生した場合

- [ ] `main.tex`ファイルが存在するか確認
- [ ] `RSL_style.sty`ファイルが存在するか確認
- [ ] `chapters/`フォルダが存在するか確認
- [ ] 異なるテンプレートの場合, `latex.config`内のパスが正しいか確認

#### ✅ エラーログの確認方法

- [ ] `.log`ファイル（`main.log`など）を直接開いてエラー内容を確認
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

## 高度な機能の利用

基本的な論文執筆環境の構築が完了したら, 必要に応じて以下の高度な機能を段階的に追加できます.

### 段階的機能利用ガイド

このテンプレートでは, 論文執筆のニーズに応じて以下の機能を段階的に追加できます:

#### Step 1: 基本的な論文執筆

**目的**: LaTeX文書の基本的な作成・ビルドのみ

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

**注意**: DVC機能を使わない場合は, `latex.config`でDVC_REMOTE_URLを空白のままにしてください.

#### Step 2: 差分表示機能の利用

**目的**: 論文の変更箇所を視覚的に確認

論文の変更箇所を視覚的に確認したい場合:

```bash
# 差分PDF生成（直前の変更を表示）
make diff

# 特定バージョン間の差分
make diff-pdf BASE=v1.0.0 CHANGED=HEAD
```

各種コマンド等の利用例は [`docs/Workflow.md`](docs/Workflow.md)を参照してください.
またコマンドの詳細は [`docs/README_DiffTool.md`](docs/README_DiffTool.md)を参照してください.

#### Step 3: DVC画像管理機能の利用

**目的**: 大容量画像ファイルのバージョン管理

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

## テンプレート使用時の整理

論文執筆開始前に, テンプレートファイルを整理することを推奨します.

### ファイル整理ガイド

#### 🗑️ 削除推奨ファイル

論文執筆開始前に以下のファイルを削除してください:

| ファイル/フォルダ   | 説明                   | 削除理由                                       |
| ------------------- | ---------------------- | ---------------------------------------------- |
| `sample.tex`        | articleサンプル文書    | サンプルのため不要                             |
| `chapters/test.tex` | テストチャプター       | サンプルのため不要                             |
| `figures/test/`     | テスト画像フォルダ     | サンプルのため不要                             |
| `README.md`         | リポジトリ概要ファイル | 独自内容に置き換え                             |
| `LICENSE`           | ライセンスファイル     | 自身の論文に対応したライセンスに差し替えor削除 |

#### ✅ 保持必須ファイル

以下のファイルは論文執筆に必要なため**必ず保持**してください:

| カテゴリ         | ファイル/フォルダ      | 説明                          | 備考                                 |
| ---------------- | ---------------------- | ----------------------------- | ------------------------------------ |
| **環境設定**     | `.devcontainer/`       | 開発環境設定                  | -                                    |
|                  | `.latexmkrc`           | LaTeXビルド設定               | -                                    |
|                  | `.latexindent.yaml`    | LaTeX自動整形設定             | -                                    |
|                  | `latex.config`         | LaTeX設定ファイル             | 作成後                               |
|                  | `latex.config.example` | LaTeX設定ファイルテンプレート | -                                    |
| **ビルド・管理** | `Makefile`             | ビルド・差分管理コマンド      | -                                    |
|                  | `scripts/`             | 支援スクリプト                | -                                    |
|                  | `docs/`                | ワークフロー・ツール説明      | -                                    |
| **Git・GitHub**  | `.github/`             | GitHub設定                    | 内容は個人の好みに合わせて設定のこと |
|                  | `.gitignore`           | Git除外設定                   | -                                    |
|                  | `.gitattributes`       | Git属性設定                   | -                                    |
| **DVC**          | `.dvcignore`           | DVC除外設定                   | DVC使用時のみ                        |
|                  | `.dvc-exclude`         | DVC除外設定                   | DVC使用時のみ                        |
| **ドキュメント** | `QUICK_START.md`       | クイックスタートガイド        | -                                    |

#### 📝 用途に応じて判断するファイル

以下のファイルはRSL卒論用のため, 他の用途では削除を検討してください:

| ファイル/フォルダ            | 説明                         | RSL卒論以外での判断        |
| ---------------------------- | ---------------------------- | -------------------------- |
| `main.tex`                   | メイン文書 (RSL卒論用)       | 他テンプレート使用時は削除 |
| `RSL_style.sty`              | スタイルファイル (RSL卒論用) | 他テンプレート使用時は削除 |
| `chapters/title.tex`         | タイトルページ               | 他テンプレート使用時は削除 |
| `chapters/chapter1.tex`      | 章テンプレート               | 他テンプレート使用時は削除 |
| `bibliography/reference.bib` | 参考文献                     | どの用途でも保持推奨       |

### 📋 異なるテンプレート使用時のTips

※ここで示しているエンジンはあくまで参考です．実際に使用する際には各テンプレートのドキュメント等を確認してください．

#### ✅ 英語系テンプレート（IEEE, ACM, Springerなど）使用時

- [ ] `latex.config`の`MAIN_TEX`を該当するメインファイル名に変更
- [ ] `latex.config`の`LATEX_ENGINE`を確認:
    - [ ] IEEE: `pdflatex`に変更
    - [ ] ACM: `pdflatex`に変更
    - [ ] Springer: `pdflatex`に変更
- [ ] `RSL_style.sty`を使用しない場合は`main.tex`から該当行を削除
- [ ] テンプレート付属のスタイルファイル（`.sty`, `.cls`）をプロジェクトルートに配置

#### ✅ 日本語系テンプレート使用時

- [ ] `latex.config`の`LATEX_ENGINE`を確認:
    - [ ] 情報処理学会: `uplatex`に変更
    - [ ] 電子情報通信学会: `uplatex`に変更
    - [ ] 人工知能学会: `pdflatex`または`uplatex`に変更
- [ ] 日本語フォント設定がテンプレートに含まれているか確認
- [ ] BibTeXスタイル（`.bst`）がテンプレート指定のものか確認

#### ✅ 卒論・修論テンプレート使用時

- [ ] 大学提供のテンプレートファイルをすべてプロジェクトルートにコピー
- [ ] `latex.config`で指定するメインファイル名を確認
- [ ] 章構成が異なる場合は`chapters/`フォルダ内のファイル構成を調整
- [ ] 参考文献スタイルが大学指定のものか確認

#### ✅ エンジン変更時の注意点

- [ ] `latex.config`の`LATEX_ENGINE`変更後, コンテナを再起動
- [ ] `.latexmkrc`ファイルの設定も必要に応じて変更
- [ ] VS Code設定の「latex-workshop.latex.recipe.default」も変更
- [ ] フォント設定がエンジンに対応しているか確認
