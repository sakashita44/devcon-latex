# PDF差分生成ツール

このドキュメントは、LaTeX プロジェクトの版間差分を可視化するツールの詳細な技術仕様について説明します。

## 概要

diff ツールは、Git 管理下の LaTeX プロジェクトにおいて、異なるバージョン間の差分を生成し、変更点を視覚化するための統合システムです。Git worktree を用いた並行復元、latexmk による統一ビルド、latexpand によるファイル展開、latexdiff による差分生成という一連のワークフローを自動化します。

なお、既存ツールの組み合わせのため、手動での再現も容易です。使えない場合はそのようにしてください。

## ツールの構成

### スクリプト一覧

diff ツールは以下のスクリプトで構成されています：

- `Makefile`: プロジェクトの統一エントリーポイント、引数の解析とデフォルト値管理
- `main.sh`: 差分生成のメインエントリーポイント、全体の制御と4種類の差分生成モード（all/pdf/images/ext）を管理
- `gen_diff_git.sh`: Git 管理ファイル（.tex, .sty, .bib など）の差分を生成
- `gen_diff_images.sh`: 画像ファイルの差分を検出・分類（added/deleted/modified）
- `gen_diff_pdf.sh`: LaTeX PDF の差分を生成（.bbl 事前生成、latexpand 展開、latexdiff 実行）
- `restore.sh`: 指定されたリビジョンをワークツリーとして復元（DVC/Git LFS 対応）
- `restore_pair.sh`: BASE/CHANGED の両リビジョンを並行復元
- `resolve_refs.sh`: Git タグやブランチ名から具体的なコミットハッシュを解決

## 基本的な使用方法

### 設定ファイルの準備

diff ツールは `config` ファイルから設定を読み込みます：

```bash
# config の設定例
DEFAULT_TARGET="src/main.tex"
DEFAULT_OUT_DIR="out/"
LATEXMK_OPTIONS="-interaction=nonstopmode"
LATEXPAND_OPTIONS="--expand-usepackage"
LATEXDIFF_OPTIONS="--type=CFONT --encoding=utf8"
```

### 基本的なコマンド実行

```bash
# 基本的な使用法（make 経由）- BASE/CHANGEDは必須
make diff BASE=v1.0 CHANGED=v1.1

# 差分生成モードの指定 - BASE/CHANGEDは必須
make diff BASE=v1.0 CHANGED=v1.1 MODE=pdf    # PDF差分のみ（※MODEは内部処理、以下のコマンドを使用）
make diff-pdf BASE=v1.0 CHANGED=v1.1         # PDF差分のみ
make diff-images BASE=v1.0 CHANGED=v1.1      # 画像差分のみ
make diff-ext BASE=v1.0 CHANGED=v1.1         # Git差分のみ

# 省略可能な引数の指定
make diff-pdf BASE=v1.0 CHANGED=v1.1 TARGET_BASE=src/main.tex TARGET_CHANGED=src/main.tex OUT=custom_output/

# 直接スクリプト実行（makeを使わない場合）
./scripts/diff/main.sh src/main.tex src/main.tex v1.0 v1.1 ./output/diff_v1.0_to_v1.1/ all
```

**引数の説明:**

- **必須引数**:
    - `BASE`: 比較元のGit参照（タグ、ブランチ、コミットハッシュ）
    - `CHANGED`: 比較先のGit参照（タグ、ブランチ、コミットハッシュ）

- **省略可能な引数**:
    - `TARGET_BASE`: BASE側の比較対象ファイル（デフォルト: `config`の`DEFAULT_TARGET`）
    - `TARGET_CHANGED`: CHANGED側の比較対象ファイル（デフォルト: `config`の`DEFAULT_TARGET`）
    - `OUT`: 出力ディレクトリ（デフォルト: `config`の`DEFAULT_OUT_DIR`）

## 出力ファイル

差分生成により、指定された出力ディレクトリに以下のファイルが生成されます：

### 共通ファイル

- `metadata.json`: 差分生成のメタデータ（BASE/CHANGED リビジョン、生成日時、設定情報）
- `logs/`: 各処理の詳細ログ（git.log, images.log, pdf.log, restore.log）

### PDF差分（MODE=pdf または all）

- `main-diff.pdf`: 差分を視覚化したPDF（メイン成果物）
- `tmp/`: 中間ファイル（base-expand.tex, changed-expand.tex, diff.tex）

### Git差分（MODE=ext または all）

- `git-diffs/`: 拡張子別の差分ファイル
    - `tex.diff`: .tex ファイルの差分
    - `sty.diff`: .sty ファイルの差分
    - `bib.diff`: .bib ファイルの差分
    - `cls.diff`: .cls ファイルの差分
    - `bst.diff`: .bst ファイルの差分
- `git-summary.csv`: Git差分のサマリー情報

### 画像差分（MODE=images または all）

- `images/`: 画像ファイルの差分
    - `added/`: CHANGED で新規追加された画像
    - `deleted/`: BASE から削除された画像
    - `modified/`: 内容が変更された画像（\_base.ext と \_changed.ext のペア）
- `image_summary.csv`: 画像差分のサマリー情報

## 技術仕様

### PDF差分生成ワークフロー

PDF差分生成は以下の詳細なワークフローで実行されます：

1. **Git Worktree 復元**
   - `git worktree add` により BASE/CHANGED の両リビジョンを並行復元
   - DVC管理ファイルは `dvc pull -f` で復元
   - Git LFS管理ファイルは `git lfs pull` で復元

2. **.bbl ファイル事前生成**
   - 各リビジョンで `latexmk` を実行し、参考文献ファイル（.bbl）を生成
   - `.latexmkrc` の探索は現在ディレクトリから上位3階層まで実行
   - 生成された.bblファイルをlatexpand用に一時配置

3. **LaTeX ファイル展開**
   - `latexpand` により `\include`/`\input` を再帰的に展開
   - 設定により `--expand-bbl` オプションで .bbl ファイルも展開可能
   - 出力: base-expand.tex, changed-expand.tex

4. **差分生成**
   - `latexdiff` により展開されたファイル間の差分を生成
   - フォールバック機能: config設定 → 基本日本語対応 → 保守的設定 → 数式無視設定
   - 出力: diff.tex

5. **差分PDF生成**
   - CHANGED側ワークツリーで diff.tex を `latexmk` によりコンパイル
   - .latexmkrc、画像ファイル等のリソースをCHANGED側から参照
   - 出力: main-diff.pdf

### 設定オプション詳細

#### config ファイル設定項目

```bash
# 基本設定
DEFAULT_TARGET="src/main.tex"           # デフォルトのメインTeXファイル
DEFAULT_OUT_DIR="out/"                  # デフォルトの出力ディレクトリ

# latexmk 設定
LATEXMK_OPTIONS="-interaction=nonstopmode -pdf"  # latexmk実行オプション（配列）

# latexpand 設定
LATEXPAND_OPTIONS="--expand-usepackage"  # latexpand実行オプション（配列）
LATEXPAND_EXPAND_BBL=1                   # .bblファイル展開の有効化（0 or 1）

# latexdiff 設定
LATEXDIFF_OPTIONS="--type=CFONT --encoding=utf8"  # latexdiff実行オプション（配列）

# 高度な設定
LATEXMKRC_EXPLORATION_RANGE=3           # .latexmkrc探索の上位階層数
KEEP_TMP_DIR=1                          # 一時ディレクトリの保持（0: 削除, 1: 保持）
GIT_DIFF_EXTENSIONS=(tex sty cls bib bst)  # Git差分対象の拡張子
IMAGE_DIFF_EXTENSIONS=(png jpg jpeg pdf eps svg)  # 画像差分対象の拡張子
```

#### 高度な機能

#### 一時ファイル保持とdiff.tex手動編集

複雑な `\input`/`\include` ネスト構造では latexdiff が正しく処理できない場合があります。この場合、以下の設定で一時ファイルを保持し、手動編集が可能です：

```bash
# config設定
KEEP_TMP_DIR=1  # 一時ディレクトリを削除しない

# 差分生成後、手動編集
make diff-pdf BASE=v1.0 CHANGED=v1.1
cd out/diff_v1.0_to_v1.1/tmp/
# diff.tex を手動編集
vim diff.tex
# 手動でPDF生成
latexmk diff.tex
```

### 対応プロジェクト構造への対応

このツールは特定のディレクトリ構造に依存せず、柔軟なプロジェクト構造に対応します。

- `TARGET_BASE`/`TARGET_CHANGED` で指定されたファイルが該当リビジョンでビルド可能であれば処理可能
- ビルド設定は各リビジョンの `.latexmkrc` または `config` の `LATEXMK_OPTIONS` に従う
- 画像ファイルやリソースはCHANGED側リビジョンのワークツリーから参照

## エラー処理とトラブルシューティング

### latexdiff フォールバック機能

`gen_diff_pdf.sh` は latexdiff エラー時に段階的にオプションを変更して再試行します：

1. **レベル1**: config設定オプション
2. **レベル2**: 基本日本語対応（`--type=CFONT --encoding=utf8`）
3. **レベル3**: 保守的設定（セクション・数式対応）
4. **レベル4**: 最保守的設定（数式無視）

### 一般的なエラーと対処法

#### PDF生成エラー

```bash
# ログファイルの確認
cat logs/pdf.log

# 中間ファイルの手動確認
ls tmp/
cat tmp/diff.tex  # latexdiff出力の確認

# 手動でPDF生成テスト
cd tmp/
latexmk diff.tex
```

## システム要件

### 必要なツール

- Git >= 2.0
- TeX Live（LuaLaTeX、latexmk、latexpand含む）
- latexdiff >= 1.3.0
- DVC（オプション）
- Git LFS（オプション）

### 対応プロジェクト構造

差分生成ツールは以下の原理で任意のプロジェクト構造に対応します：

1. **Git Worktree による独立復元**: 各リビジョン（BASE/CHANGED）を独立したディレクトリに復元するため、それぞれのリビジョンで異なるディレクトリ構造を持つことが可能

2. **リビジョン固有の設定参照**: 各ワークツリーで `.latexmkrc` や `config` ファイルを個別に読み込むため、リビジョンごとに異なるビルド設定が適用される

3. **相対パス解決**: latexmk と latexpand は各ワークツリー内で相対パスを解決するため、ファイル参照が正常に機能する

#### 必要な条件

1. **ビルド可能性**: 指定された `TARGET_BASE`/`TARGET_CHANGED` ファイルが該当リビジョンで `latexmk` によりビルド可能
2. **相対パス参照**: `\include`, `\input`, `\includegraphics` 等は相対パスで記述
3. **設定ファイル配置**: `.latexmkrc` がビルド対象ファイルから検索可能な位置に配置（通常は同一ディレクトリ）

## 制限事項と既知の問題

### 技術的制限

- 差分PDF生成には最低2つのGitバージョン（タグ・コミット・ブランチ）が必要
- latexdiff は複雑な LaTeX 構造（tikz、複雑な数式など）で失敗する場合がある
- DVC管理ファイルは該当リビジョンでアクセス可能である必要がある
- .bbl ファイル生成のため、各リビジョンで完全なLaTeXビルドが実行される

### 既知の回避策

- latexdiff エラー時は自動フォールバック機能により段階的にオプションを変更
- 複雑な構造のファイルは `LATEXDIFF_OPTIONS` で除外コマンドを指定
- 大規模画像を含むプロジェクトでは `MODE=pdf` または `MODE=ext` で処理を分割
- 複雑な `\input`/`\include` ネスト構造では手動調整が必要な場合あり
- 図表ファイルは相対パスで記述する必要あり
- `\includeonly` コマンドは現在未対応
- 大量のファイルでは処理時間が長くなる場合あり
- エンジン変更時は `.latexmkrc` の適切な調整が必要
