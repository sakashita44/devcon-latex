#!/usr/bin/env bash
set -euo pipefail

#
# 概要: 2つのリビジョンの.texファイルから、差分PDFを生成する。
#       .bblファイルの事前生成により、参考文献の差分精度を向上させる。
#
# 引数:
#   $1: TARGET_BASE (BASE側の.texファイルパス)
#   $2: TARGET_CHANGED (CHANGED側の.texファイルパス)
#   $3: BASE_REPO_PATH (BASE側のワークツリーパス)
#   $4: CHANGED_REPO_PATH (CHANGED側のワークツリーパス)
#   $5: DIFF_OUT_DIR (成果物の出力先ディレクトリ)
#
# 依存設定 (config):
#   - LATEXMK_OPTIONS (配列)
#   - LATEXPAND_OPTIONS (配列)
#   - LATEDIFF_OPTIONS (配列)
#

# === 引数チェック ===
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_BASE> <TARGET_CHANGED> <BASE_REPO_PATH> <CHANGED_REPO_PATH> <DIFF_OUT_DIR>" >&2
    exit 1
fi

TARGET_BASE=$1
TARGET_CHANGED=$2
BASE_REPO_PATH=$3
CHANGED_REPO_PATH=$4
DIFF_OUT_DIR=$5

echo "PDF diff generation (placeholder)"
echo "TARGET_BASE: $TARGET_BASE"
echo "TARGET_CHANGED: $TARGET_CHANGED"
echo "BASE_REPO_PATH: $BASE_REPO_PATH"
echo "CHANGED_REPO_PATH: $CHANGED_REPO_PATH"
echo "DIFF_OUT_DIR: $DIFF_OUT_DIR"

# プレースホルダー: 成功を返す
echo "PDF diff generation completed (placeholder)"
exit 0

# === 初期設定 ===
# TODO: common.shとconfigを読み込む
# TODO: configで定義された配列変数が未定義の場合に備え、空配列で初期化する

# === .bbl ファイルの事前生成 ===
# TODO: BASE側でlatexmkを実行し、.bblファイルを生成する
# TODO: CHANGED側でlatexmkを実行し、.bblファイルを生成する
# TODO: .bblファイルが両方とも生成されたか確認する

# === .tex ファイルの展開 (latexpand) ===
# TODO: BASE側の.texファイルをlatexpandで展開し、一時ファイルに保存する
# TODO: CHANGED側の.texファイルをlatexpandで展開し、一時ファイルに保存する

# === 差分.tex ファイルの生成 (latexdiff) ===
# TODO: 展開された2つの.texファイルから、latexdiffで差分.tex (diff.tex) を生成する

# === 差分PDFのビルド ===
# TODO: 生成したdiff.texをCHANGED側のワークツリーに配置する
# TODO: CHANGED側のワークツリーでlatexmkを実行し、差分PDFをビルドする
# TODO: ビルドされたPDFを $5/main-diff.pdf としてコピーする

# === 結果の報告 ===
# TODO: 成功または失敗を標準出力に報告する (main.shが解釈するため)
