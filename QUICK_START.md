# クイックスタートガイド

すぐに論文執筆を開始したい人向けのガイド

## 🚀 クイックスタート

このガイドはVS CodeとDev Containerを使用してLaTeX論文執筆を始めるための簡単な手順を提供します．以下のチェックリストに従って必要な準備を行い，論文執筆を開始してください．

### ✅ 事前準備チェックリスト

- [ ] VS Codeをインストール済み
- [ ] VS Codeの拡張機能「Dev Containers」をインストール済み
- [ ] VS Codeの拡張機能「LaTeX Workshop」をインストール済み
- [ ] Dockerをインストール済み（Docker Desktopなど）

### ✅ 論文執筆開始チェックリスト

#### Step 1: 環境起動（初回のみ）

- [ ] このリポジトリをクローンまたはテンプレートとして使用
- [ ] VS Codeで開く
- [ ] 右下に表示される「Reopen in Container」をクリック
- [ ] コンテナ起動完了まで待機（初回は10-15分）

#### Step 2: 基本設定（初回のみ）

- [ ] 設定ファイルを作成: `cp latex.config.example latex.config`
- [ ] DVC機能を使わない場合は`latex.config`内の`DVC_REMOTE_URL`を空白のまま保持

#### Step 3: 論文執筆開始

- [ ] `main.tex`を開いて執筆開始
- [ ] 異なるテンプレートを使用する場合は, `latex.config`内の`MAIN_TEX`等を確認
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

### 📋 異なるテンプレート使用時のTips

※ここで示しているエンジンはあくまで参考です．実際に使用する際には各テンプレートのドキュメント等を確認してください．

#### ✅ 学会テンプレート（IEEE, ACM, Springerなど）使用時

- [ ] `latex.config`の`MAIN_TEX`を該当するメインファイル名に変更
- [ ] `latex.config`の`LATEX_ENGINE`を確認:
    - [ ] IEEE: `pdflatex`に変更
    - [ ] ACM: `pdflatex`に変更
    - [ ] Springer: `pdflatex`に変更
- [ ] `RSL_style.sty`を使用しない場合は`main.tex`から該当行を削除
- [ ] テンプレート付属のスタイルファイル（`.sty`, `.cls`）をプロジェクトルートに配置

#### ✅ 日本語学会テンプレート使用時

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
