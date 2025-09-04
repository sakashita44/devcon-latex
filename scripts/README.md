# スクリプト詳細仕様

このディレクトリには、LaTeX論文執筆と差分生成を支援するスクリプト群が含まれています。

## ディレクトリ構成

```text
scripts/
├── common.sh              # 共通関数・ユーティリティ
├── gen_config_mk.sh       # 設定ファイル処理
├── build/
│   └── build.sh          # LaTeXビルド処理
├── diff/                 # 差分生成システム
│   ├── main.sh           # 差分生成メイン処理
│   ├── gen_diff_git.sh   # Git差分生成
│   ├── gen_diff_images.sh # 画像差分検出
│   ├── gen_diff_pdf.sh   # PDF差分生成
│   ├── resolve_refs.sh   # Git参照解決
│   ├── restore.sh        # 差分生成用ファイル復元
│   └── restore_pair.sh   # ペア復元処理
└── validate/             # バリデーション機能
    ├── validate_git.sh   # Git状態確認
    ├── validate_latex.sh # LaTeX状態確認
    └── validate_tags.sh  # タグ重複確認
```

## 主要スクリプト

### 共通関数（common.sh）

全スクリプトで使用される共通関数とユーティリティを提供。

#### メッセージ関数

* `log_info(message)` - 情報メッセージ表示
* `log_success(message)` - 成功メッセージ表示
* `log_warning(message)` - 警告メッセージ表示
* `log_error(message)` - エラーメッセージ表示

#### ユーティリティ関数

* `find_git_root()` - Gitリポジトリルート検索
* `create_temp_dir(prefix)` - 一時ディレクトリ作成
* `cleanup_temp_dir(dir)` - 一時ディレクトリ削除
* `validate_file_exists(file)` - ファイル存在確認

#### 使用例

```bash
# スクリプト内での読み込み
source "$(dirname "$0")/common.sh"

# 関数の使用
log_info "処理を開始します"
TEMP_DIR=$(create_temp_dir "diff_work")
```

### 設定ファイル処理（gen_config_mk.sh）

`config`ファイルから`.config.mk`を生成し、Makefileで使用可能な形式に変換。

```bash
./scripts/gen_config_mk.sh config .config.mk
```

### ビルドシステム（build/build.sh）

LaTeX文書のビルド、監視、クリーンアップを統一的に処理。

#### サポート機能

* `build` - 指定されたTeXファイルのビルド
* `watch` - ファイル変更監視による自動ビルド
* `clean` - 一時ファイルと出力ファイルのクリーンアップ

```bash
./scripts/build/build.sh build "src/main.tex"
./scripts/build/build.sh watch "src/main.tex"
./scripts/build/build.sh clean "src/main.tex"
```

## 差分生成システム（diff/）

### メイン処理（main.sh）

4つのモードで差分生成を統括管理。

#### 実行モード

* `all` - 全ての差分生成（PDF、画像、Git差分、メタデータ）
* `pdf` - PDF差分のみ生成
* `images` - 画像差分のみ検出
* `ext` - 拡張子別Git差分のみ生成

```bash
MODE=all bash ./scripts/diff/main.sh "src/main.tex" "src/main.tex" "v1.0" "v2.0" "out/"
```

#### 出力構造

```text
out/diff_v1.0_to_v2.0/
├── metadata.json          # 実行情報とサマリ
├── main-diff.pdf          # PDF差分（MODE=pdf,all時）
├── git_summary.csv        # Git差分サマリ
├── image_summary.csv      # 画像差分サマリ
├── git-diffs/             # 拡張子別差分
│   ├── tex.diff
│   ├── bib.diff
│   └── sty.diff
├── images/                # 画像差分
│   ├── added/             # 追加画像
│   ├── deleted/           # 削除画像
│   └── modified/          # 変更画像
└── logs/                  # 実行ログ
    ├── git.log
    ├── images.log
    └── pdf.log
```

### Git差分生成（gen_diff_git.sh）

指定したGit参照間でファイル拡張子ごとの差分を生成。

```bash
./scripts/diff/gen_diff_git.sh "v1.0" "v2.0" "out/diff_output" "tex bib sty"
```

### 画像差分検出（gen_diff_images.sh）

画像ファイルの追加・削除・変更を検出し分類。

```bash
./scripts/diff/gen_diff_images.sh "v1.0" "v2.0" "out/diff_output" "png jpg pdf"
```

### PDF差分生成（gen_diff_pdf.sh）

LaTeX文書の視覚的差分PDFを`latexdiff`で生成。

```bash
./scripts/diff/gen_diff_pdf.sh "src/main.tex" "src/main.tex" "v1.0" "v2.0" "out/diff_output"
```

### Git参照解決（resolve_refs.sh）

Git参照（タグ、ブランチ、コミットハッシュ）を実際のコミットハッシュに解決。

```bash
./scripts/diff/resolve_refs.sh "v1.0" "HEAD"
# 出力例: abc123ef def456gh
```

### 復元処理（restore.sh, restore_pair.sh）

差分生成時に使用する一時的なファイル復元処理。

## バリデーション機能（validate/）

### Git状態確認（validate_git.sh）

リポジトリの状態確認とクリーンアップ状況の検証。

```bash
./scripts/validate/validate_git.sh
```

### LaTeX状態確認（validate_latex.sh）

指定されたTeXファイルとその依存関係の確認。

```bash
./scripts/validate/validate_latex.sh "src/main.tex"
```

### タグ重複確認（validate_tags.sh）

Gitタグの重複確認。

```bash
./scripts/validate/validate_tags.sh "v2.0"
```

## 設定とカスタマイズ

### 設定ファイル（config）

主要な設定パラメータ：

```bash
# ビルド関係
DEFAULT_TARGET=src/main.tex
DEFAULT_OUT_DIR=out/
LATEXMK_OPTIONS=()

# 差分生成関係
GIT_DIFF_EXTENSIONS=(tex sty cls bib bst)
IMAGE_DIFF_EXTENSIONS=(png jpg jpeg pdf eps svg)
KEEP_TMP_DIR=0
```

### 実行例

#### ビルド関連

```bash
make build                              # デフォルトターゲット
make build TARGET=src/lualatex-jp-test/main.tex  # 特定ターゲット
```

#### 差分生成

```bash
make diff-pdf BASE=v1.0 CHANGED=v2.0   # PDF差分
make diff BASE=v1.0 CHANGED=HEAD       # 全差分生成
```

#### バリデーション

```bash
make validate                           # 全体確認
make validate-latex TARGET=src/main.tex # LaTeX確認
```

## エラーハンドリング

全スクリプトで統一されたエラーハンドリング：

* `set -e` によるエラー時即座終了
* 共通関数による統一メッセージフォーマット
* 適切な終了コード設定
* 詳細なログ出力

## デバッグ

スクリプトデバッグ時の推奨方法：

```bash
# デバッグモード実行
bash -x ./scripts/diff/main.sh

# 一時ディレクトリ保持
KEEP_TMP_DIR=1 make diff-pdf BASE=v1.0 CHANGED=v2.0

# ログ確認
cat out/diff_v1.0_to_v2.0/logs/pdf.log
```

各スクリプトは独立して実行可能で、Makefileを経由せずに直接テストできます。
