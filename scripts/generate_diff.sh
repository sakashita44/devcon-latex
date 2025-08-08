#!/bin/bash

# Git-LaTeX 差分PDF生成スクリプト
# 仕様: 2つのGitバージョン間のLaTeX差分PDFを生成

set -e  # エラー時にスクリプトを停止

# 色付き出力用の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 関数: ログ出力
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用方法を表示
show_usage() {
    cat << EOF
使用方法: $0 <main_tex_file> <base_version> <changed_version>

引数:
  main_tex_file    プロジェクトのメインとなる.texファイル名 (例: main.tex)
  base_version     比較元となるGitのバージョン (タグ、コミットID、ブランチ名など)
  changed_version  比較先となるGitのバージョン

例:
  $0 main.tex v1.0.0 test
  $0 main.tex HEAD~1 HEAD
EOF
}

# 1. 初期化
log_info "Git-LaTeX差分PDF生成を開始します..."

# 引数チェック
if [ $# -ne 3 ]; then
    log_error "引数が不足しています"
    show_usage
    exit 1
fi

MAIN_TEX="$1"
BASE_VERSION="$2"
CHANGED_VERSION="$3"

log_info "設定:"
log_info "  メインファイル: $MAIN_TEX"
log_info "  比較元バージョン: $BASE_VERSION"
log_info "  比較先バージョン: $CHANGED_VERSION"

# Gitバージョンの存在確認
if ! git rev-parse --verify "$BASE_VERSION" >/dev/null 2>&1; then
    log_error "比較元バージョン '$BASE_VERSION' が見つかりません"
    exit 1
fi

if ! git rev-parse --verify "$CHANGED_VERSION" >/dev/null 2>&1; then
    log_error "比較先バージョン '$CHANGED_VERSION' が見つかりません"
    exit 1
fi

# 作業用ディレクトリの初期化
WORK_DIR="diff_output"
log_info "作業用ディレクトリを初期化中: $WORK_DIR"

if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

mkdir -p "$WORK_DIR/base"
mkdir -p "$WORK_DIR/changed"

# 2. ファイルの抽出
log_info "ファイルを抽出中..."

# LaTeX関連ファイルの抽出関数
extract_latex_files() {
    local version="$1"
    local target_dir="$2"

    log_info "  $version からLaTeX関連ファイルを抽出中..."

    # LaTeX関連ファイルの拡張子
    local extensions="*.tex *.bib *.cls *.sty"

    # git ls-tree を使用してファイル一覧を取得し、ファイルを抽出
    git ls-tree -r --name-only "$version" | grep -E '\.(tex|bib|cls|sty)$' | while read -r file; do
        # ディレクトリ構造を維持してファイルを作成
        local target_file="$target_dir/$file"
        local target_dirname=$(dirname "$target_file")

        mkdir -p "$target_dirname"
        git show "$version:$file" > "$target_file"
    done
}

# 画像ファイルの抽出関数（最新版のみ）
extract_image_files() {
    local version="$1"
    local target_dir="$2"

    log_info "  $version から画像ファイルを抽出中..."

    # 画像ファイルの拡張子
    git ls-tree -r --name-only "$version" | grep -E '\.(png|jpg|jpeg|pdf|eps|svg)$' | while read -r file; do
        local target_file="$target_dir/$file"
        local target_dirname=$(dirname "$target_file")

        mkdir -p "$target_dirname"
        git show "$version:$file" > "$target_file"
    done
}

# ファイル抽出実行
extract_latex_files "$BASE_VERSION" "$WORK_DIR/base"
extract_latex_files "$CHANGED_VERSION" "$WORK_DIR/changed"

# 画像ファイルは最新版（changed_version）のものを使用
extract_image_files "$CHANGED_VERSION" "$WORK_DIR"

# ルートレベルのスタイルファイル等もコピー
log_info "  ルートレベルのファイルをコピー中..."
for ext in "sty" "cls" "bib"; do
    find . -maxdepth 1 -name "*.$ext" -exec cp {} "$WORK_DIR/" \;
done

# bibliographyディレクトリもコピー（存在する場合）
if [ -d "bibliography" ]; then
    log_info "  bibliographyディレクトリをコピー中..."
    cp -r bibliography "$WORK_DIR/"
fi

# メインファイルの存在確認
if [ ! -f "$WORK_DIR/base/$MAIN_TEX" ]; then
    log_error "比較元バージョンにメインファイル '$MAIN_TEX' が見つかりません"
    exit 1
fi

if [ ! -f "$WORK_DIR/changed/$MAIN_TEX" ]; then
    log_error "比較先バージョンにメインファイル '$MAIN_TEX' が見つかりません"
    exit 1
fi

# 3. ソースの平坦化
log_info "ソースファイルを平坦化中..."

# 平坦化実行
log_info "  作業ディレクトリ: $(pwd)"
cd "$WORK_DIR/base"
log_info "  比較元バージョンを平坦化中... (現在: $(pwd))"
latexpand "$MAIN_TEX" > "../main-base.tex"

cd "../changed"
log_info "  比較先バージョンを平坦化中... (現在: $(pwd))"
latexpand "$MAIN_TEX" > "../main-changed.tex"

cd ".."
log_info "  平坦化後のディレクトリ: $(pwd)"

# 平坦化結果の確認
if [ ! -f "main-base.tex" ] || [ ! -s "main-base.tex" ]; then
    log_error "比較元の平坦化に失敗しました"
    exit 1
fi

if [ ! -f "main-changed.tex" ] || [ ! -s "main-changed.tex" ]; then
    log_error "比較先の平坦化に失敗しました"
    exit 1
fi

log_success "平坦化完了"
log_info "  main-base.tex: $(wc -l < main-base.tex) 行"
log_info "  main-changed.tex: $(wc -l < main-changed.tex) 行"

# 4. 差分ファイルの生成
log_info "差分ファイルを生成中..."

latexdiff main-base.tex main-changed.tex > main-diff.tex

if [ ! -f "main-diff.tex" ] || [ ! -s "main-diff.tex" ]; then
    log_error "差分ファイルの生成に失敗しました"
    exit 1
fi

log_success "差分ファイル生成完了: main-diff.tex"

# 5. PDFへのコンパイル
log_info "PDFをコンパイル中..."

# ルートの.latexmkrcを使用（作業ディレクトリの外のルート）
cp ../.latexmkrc .

# latexmkの設定
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# コンパイル実行(latexmkを参照)
latexmk main-diff.tex

if [ ! -f "main-diff.pdf" ]; then
    log_error "PDFコンパイルに失敗しました"
    log_info "詳細なエラーログを確認してください: $WORK_DIR/main-diff.log"
    exit 1
fi

log_success "PDFコンパイル完了: main-diff.pdf"

# 6. 完了報告
log_info "変更ファイルの確認..."

# LaTeX関連ファイルのgit diff保存
log_info "LaTeX関連ファイルのGit差分を保存中..."

# LaTeX関連ファイルの拡張子パターン
LATEX_EXTENSIONS='\.(tex|bib|cls|sty)$'

# LaTeX関連ファイルの変更リストを取得
CHANGED_LATEX_FILES=$(git diff --name-only "$BASE_VERSION" "$CHANGED_VERSION" | grep -E "$LATEX_EXTENSIONS" || true)

if [ -n "$CHANGED_LATEX_FILES" ]; then
    # 現在のディレクトリを保存
    CURRENT_DIR=$(pwd)
    log_info "  現在のディレクトリ: $CURRENT_DIR"

    # 親ディレクトリでgit diffを実行して結果を保存
    cd ..
    log_info "  Git diffを実行中: $(pwd)"
    git diff "$BASE_VERSION" "$CHANGED_VERSION" -- $(echo "$CHANGED_LATEX_FILES" | tr '\n' ' ') > "$WORK_DIR/git-diff.diff"

    # 元のディレクトリに戻る
    cd "$CURRENT_DIR"
    log_info "  ディレクトリを復元: $(pwd)"

    log_info "    echo "[INFO] LaTeX関連ファイルのGit差分を git-diff.diff に保存しました""
    log_info "変更されたLaTeX関連ファイル:"
    echo "$CHANGED_LATEX_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    log_info "LaTeX関連ファイルに変更はありません"
fi

# 変更された画像ファイルの検出
CHANGED_IMAGES=$(git diff --name-only "$BASE_VERSION" "$CHANGED_VERSION" | grep -E '\.(png|jpg|jpeg|pdf|eps|svg)$' || true)

# 変更されたbibファイルの検出
CHANGED_BIBS=$(git diff --name-only "$BASE_VERSION" "$CHANGED_VERSION" | grep -E '\.bib$' || true)

if [ -n "$CHANGED_IMAGES" ]; then
    log_warning "以下の画像ファイルが変更されています（目視確認推奨）:"
    echo "$CHANGED_IMAGES" | while read -r img; do
        echo "  - $img"
    done

    # 変更された画像を diff-img ディレクトリに保存
    mkdir -p diff-img
    echo "$CHANGED_IMAGES" | while read -r img; do
        if [ -f "../$img" ]; then
            cp "../$img" "diff-img/"
        fi
    done
    log_info "変更された画像ファイルを diff-img/ にコピーしました"
else
    log_info "画像ファイルに変更はありません"
fi

if [ -n "$CHANGED_BIBS" ]; then
    log_warning "以下の参考文献ファイル(.bib)が変更されています（目視確認推奨）:"
    echo "$CHANGED_BIBS" | while read -r bib; do
        echo "  - $bib"
    done

    # 変更されたbibファイルを diff-bib ディレクトリに保存
    mkdir -p diff-bib
    echo "$CHANGED_BIBS" | while read -r bib; do
        # 新旧両方のbibファイルを保存
        local bib_basename=$(basename "$bib")
        git show "$BASE_VERSION:$bib" > "diff-bib/${bib_basename}.old" 2>/dev/null || true
        git show "$CHANGED_VERSION:$bib" > "diff-bib/${bib_basename}.new" 2>/dev/null || true
    done
    log_info "変更された参考文献ファイルを diff-bib/ にコピーしました（.old/.newで比較可能）"
else
    log_info "参考文献ファイルに変更はありません"
fi

# ファイルサイズ情報
PDF_SIZE=$(du -h main-diff.pdf | cut -f1)

# 一時ファイルの削除（確認すべきファイルのみ残す）
log_info "一時ファイルを削除中..."

# 削除するディレクトリ・ファイル
rm -rf base/ changed/ figures/ bibliography/
rm -f RSL_style.sty main-base.tex main-changed.tex .latexmkrc
rm -f main-diff.aux main-diff.bbl main-diff.blg main-diff.fdb_latexmk main-diff.fls main-diff.log main-diff.out main-diff.toc

log_info "一時ファイルを削除しました"

# 最終報告
log_success "差分PDF生成が完了しました！"
log_info "生成されたファイル:"
log_info "  差分PDF: $(pwd)/main-diff.pdf ($PDF_SIZE)"
log_info "  差分TeX: $(pwd)/main-diff.tex"
if [ -f "git-diff.diff" ]; then
    DIFF_SIZE=$(du -h git-diff.diff | cut -f1)
    log_info "  Git差分: $(pwd)/git-diff.diff ($DIFF_SIZE)"
fi
if [ -d "diff-img" ]; then
    log_info "  変更画像: $(pwd)/diff-img/"
fi
if [ -d "diff-bib" ]; then
    log_info "  変更参考文献: $(pwd)/diff-bib/ (.old/.newで比較)"
fi
log_info "  比較元: $BASE_VERSION"
log_info "  比較先: $CHANGED_VERSION"

log_info "処理完了！差分PDFは $WORK_DIR/main-diff.pdf に保存されました"
