# 設定例とカスタマイズガイド

このドキュメントでは、LaTeX論文執筆プロジェクトの設定ファイルの詳細と、様々な環境での設定例を説明します。

## 設定ファイルの概要

### 設定ファイルの構成

このプロジェクトでは以下の設定ファイルを使用します：

- `config`: メインの設定ファイル（`config.example`をコピーして作成）
- `src/.latexmkrc`: LaTeXビルド設定
- `.latexindent.yaml`: LaTeX自動整形設定（オプション）

## config ファイル詳細解説

### 基本ビルド設定

#### DEFAULT_TARGET

```bash
DEFAULT_TARGET=src/main.tex
```

- **用途**: `make build` 等でTARGETが指定されない場合に使用される
- **設定例**:
    - RSL卒論: `DEFAULT_TARGET=src/main.tex`
    - ルート配置: `DEFAULT_TARGET=main.tex`
    - 複数文書: `DEFAULT_TARGET=paper1/main.tex`

#### LATEXMK_OPTIONS

```bash
LATEXMK_OPTIONS=()
```

- **用途**: latexmk実行時のオプション（配列形式）
- **デフォルト**: 空配列（`.latexmkrc`の設定を使用）
- **設定例**:

  ```bash
  # 中間ファイル削除と出力抑制
  LATEXMK_OPTIONS=("-c" "-silent")

  # 強制再ビルド
  LATEXMK_OPTIONS=("-gg")

  # インタラクション無効
  LATEXMK_OPTIONS=("-interaction=nonstopmode")
  ```

#### LATEXPAND_OPTIONS

```bash
LATEXPAND_OPTIONS=("--empty-comments")
```

- **用途**: latexpand実行時のオプション（配列形式）
- **注意**: `--expand-bbl`は自動制御されるため指定不要
- **設定例**:

  ```bash
  # 基本設定
  LATEXPAND_OPTIONS=("--empty-comments")

  # usepackageも展開
  LATEXPAND_OPTIONS=("--expand-usepackage" "--empty-comments")

  # より詳細な展開
  LATEXPAND_OPTIONS=("--expand-usepackage" "--expand-bbl" "--empty-comments")
  ```

#### LATEXPAND_EXPAND_BBL

```bash
LATEXPAND_EXPAND_BBL=0
```

- **用途**: `--expand-bbl`オプションの使用制御
- **値**: `0`（使用しない）または `1`（使用する）
- **推奨**: 参考文献の差分精度向上のため `1` を推奨

#### LATEXDIFF_OPTIONS

```bash
LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--math-markup=whole" "--exclude-textcmd=section,subsection,subsubsection")
```

- **用途**: latexdiff実行時のオプション（配列形式）
- **設定例**:

  ```bash
  # 日本語対応基本設定
  LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8")

  # 数式対応強化
  LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--math-markup=whole")

  # セクション除外
  LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--exclude-textcmd=section,subsection,subsubsection")

  # 保守的設定（複雑な文書用）
  LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--math-markup=off")
  ```

#### LATEXMKRC_EXPLORATION_RANGE

```bash
LATEXMKRC_EXPLORATION_RANGE=3
```

- **用途**: `.latexmkrc`ファイルの探索範囲（階層数）
- **動作**: ターゲットファイルから上位何階層まで`.latexmkrc`を探索するか
- **推奨値**: `3`（通常のプロジェクト構造に対応）

### 差分生成設定

#### DEFAULT_OUT_DIR

```bash
DEFAULT_OUT_DIR=out/
```

- **用途**: `make diff`でOUT_DIRが指定されない場合の出力先
- **設定例**:
    - 標準: `DEFAULT_OUT_DIR=out/`
    - カスタム: `DEFAULT_OUT_DIR=diff_output/`
    - 絶対パス: `DEFAULT_OUT_DIR=/tmp/diff/`

#### KEEP_TMP_DIR

```bash
KEEP_TMP_DIR=0
```

- **用途**: `make diff`で使用される一時ディレクトリの保持設定（デバッグ用）
- **値**: `0`（削除）または `1`（保持）
- **使用場面**: latexdiff失敗時の手動調整で `1` に設定

#### GIT_DIFF_EXTENSIONS

```bash
GIT_DIFF_EXTENSIONS=(tex sty cls bib bst)
```

- **用途**: Git差分出力対象の拡張子リスト
- **設定例**:

  ```bash
  # 基本設定
  GIT_DIFF_EXTENSIONS=(tex sty cls bib bst)

  # 追加拡張子
  GIT_DIFF_EXTENSIONS=(tex sty cls bib bst tikz def)

  # 最小設定
  GIT_DIFF_EXTENSIONS=(tex bib)
  ```

#### IMAGE_DIFF_EXTENSIONS

```bash
IMAGE_DIFF_EXTENSIONS=(png jpg jpeg pdf eps svg)
```

- **用途**: 画像差分検出対象の拡張子リスト
- **設定例**:

  ```bash
  # 基本設定
  IMAGE_DIFF_EXTENSIONS=(png jpg jpeg pdf eps svg)

  # 追加形式
  IMAGE_DIFF_EXTENSIONS=(png jpg jpeg pdf eps svg tiff bmp gif)

  # ベクター形式のみ
  IMAGE_DIFF_EXTENSIONS=(pdf eps svg)
  ```

### ログ設定

#### LOG_DIR

```bash
LOG_DIR=log
```

- **用途**: ログ保存ディレクトリ（リポジトリルートに作成）
- **設定例**:
    - 標準: `LOG_DIR=log`
    - 隠しディレクトリ: `LOG_DIR=.logs`

#### LOG_CAPTURE_DEFAULT

```bash
LOG_CAPTURE_DEFAULT=0
```

- **用途**: stdout/stderrキャプチャの有効化
- **値**: `0`（メタデータのみ）または `1`（全出力保存）

#### LOG_TIMESTAMP_FORMAT

```bash
LOG_TIMESTAMP_FORMAT=%Y%m%d-%H%M%S
```

- **用途**: ログファイルのタイムスタンプ形式
- **形式**: strftime形式
- **設定例**:

  ```bash
  # 標準形式
  LOG_TIMESTAMP_FORMAT=%Y%m%d-%H%M%S

  # ISO形式
  LOG_TIMESTAMP_FORMAT=%Y-%m-%dT%H:%M:%S

  # 簡易形式
  LOG_TIMESTAMP_FORMAT=%m%d_%H%M
  ```

## .latexmkrc ファイル詳細解説

### .latexmkrc基本構造

```perl
# 出力ディレクトリをout/に設定
$out_dir = '../out';

# LuaLaTeX設定
$pdf_mode = 4;  # LuaLaTeX
$lualatex = 'lualatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;
$max_repeat = 5;  # 最大繰り返し回数

# BibTeX設定
$ENV{'BIBINPUTS'} = './bibliography/:' . ($ENV{'BIBINPUTS'} || '');

# クリーンアップ対象
$clean_ext = "aux bbl blg fdb_latexmk fls log nav out snm toc";
```

### エンジン別設定例

#### LuaLaTeX（推奨）

```perl
$pdf_mode = 4;
$lualatex = 'lualatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;
```

- **用途**: 日本語対応、現代的なフォント処理
- **対応**: 日本語論文、複雑な図表

#### pdfLaTeX

```perl
$pdf_mode = 1;
$pdflatex = 'pdflatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;
```

- **用途**: 英語論文、軽量処理
- **対応**: IEEE、ACM、Springer等のテンプレート

#### upLaTeX

```perl
$pdf_mode = 3;
$latex = 'uplatex -interaction=nonstopmode %O %S';
$dvipdf = 'dvipdfmx %O -o %D %S';
$bibtex_use = 2;
```

- **用途**: 日本語学会テンプレート
- **対応**: 情報処理学会、電子情報通信学会等

#### XeLaTeX

```perl
$pdf_mode = 5;
$xelatex = 'xelatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;
```

- **用途**: 多言語対応、システムフォント使用
- **対応**: 多言語論文、特殊フォント要求

### 出力ディレクトリ設定

```perl
# src/構造の場合
$out_dir = '../out';

# ルート配置の場合
$out_dir = './out';

# 絶対パス指定
$out_dir = '/tmp/latex_output';
```

### BibTeX設定

```perl
# 標準設定
$bibtex_use = 2;

# BibTeX無効
$bibtex_use = 0;

# 検索パス設定
$ENV{'BIBINPUTS'} = './bibliography/:./refs/:' . ($ENV{'BIBINPUTS'} || '');
```

### クリーンアップ設定

```perl
# 基本クリーンアップ
$clean_ext = "aux bbl blg fdb_latexmk fls log";

# 詳細クリーンアップ
$clean_ext = "aux bbl blg fdb_latexmk fls log nav out snm toc synctex.gz run.xml";

# 最小クリーンアップ
$clean_ext = "aux log";
```

## 環境別設定例

### RSL卒論環境

```bash
# config
DEFAULT_TARGET=src/main.tex
DEFAULT_OUT_DIR=out/
LATEXMK_OPTIONS=()
LATEXPAND_OPTIONS=("--empty-comments")
LATEXPAND_EXPAND_BBL=1
LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--math-markup=whole")
```

```perl
# src/.latexmkrc
$out_dir = '../out';
$pdf_mode = 4;
$lualatex = 'lualatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;
$ENV{'BIBINPUTS'} = './bibliography/:' . ($ENV{'BIBINPUTS'} || '');
```

## トラブルシューティング設定

### latexdiff失敗時の対応

```bash
# config（デバッグ用）
KEEP_TMP_DIR=1
LATEXDIFF_OPTIONS=("--type=CFONT" "--encoding=utf8" "--math-markup=off")
```

## ベストプラクティス

### 設定ファイル管理

1. **バージョン管理**: 環境変数を使用していないため、`config`ファイルもGit管理して共有することを推奨
2. **テンプレート管理**: `config.example`は設定例として保持し、初期設定の参考にする
3. **相対パス使用**: 絶対パスではなく相対パスを使用してポータビリティを確保
4. **設定の統一**: チーム開発では統一された設定を使用して環境の違いを最小化

### パフォーマンス最適化

1. **差分対象の絞り込み**: 不要な拡張子を除外
2. **ログレベル調整**: 本番では`LOG_CAPTURE_DEFAULT=0`
3. **一時ファイル管理**: `KEEP_TMP_DIR=0`で自動削除

### セキュリティ考慮

1. **出力先の制限**: システムディレクトリへの出力を避ける
2. **コマンド制限**: 危険なlatexmkオプションの使用を避ける
3. **パス検証**: 相対パスの使用を推奨

## 設定変更時のチェックリスト

### config変更後

- [ ] `make validate`でエラーチェック
- [ ] `make build`でビルド確認
- [ ] 差分生成テスト実行

### .latexmkrc変更後

- [ ] コンテナ再起動
- [ ] VS Code設定確認
- [ ] フォント設定確認
- [ ] ビルド成功確認

### 設定ファイル共有時

- [ ] 相対パスの使用確認
- [ ] ビルド・差分生成テスト実行
- [ ] 複数環境での動作確認
- [ ] 必要に応じてドキュメント更新
