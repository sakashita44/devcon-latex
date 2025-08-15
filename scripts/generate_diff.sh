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
使用方法: $0 <target_tex_file> <base_version> <changed_version>

引数:
  target_tex_file  ビルド対象の.texファイルのパス (例: src/main.tex, src/jp/main.tex)
  base_version     比較元となるGitのバージョン (タグ、コミットID、ブランチ名など)
  changed_version  比較先となるGitのバージョン

例:
  $0 src/main.tex v1.0.0 test
  $0 src/jp/main.tex HEAD~1 HEAD
  $0 src/TNSRE/main.tex v1.0 v2.0
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

# TARGET指定からファイル名とソースディレクトリを抽出
TARGET_FILE="$MAIN_TEX"
SRC_DIR="$(dirname "$TARGET_FILE")"
MAIN_TEX_NAME="$(basename "$TARGET_FILE")"

log_info "設定:"
log_info "  ターゲットファイル: $TARGET_FILE"
log_info "  ソースディレクトリ: $SRC_DIR"
log_info "  メインファイル名: $MAIN_TEX_NAME"
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

# 作業用ディレクトリの初期化（タグ間の差分を明示）
# ディレクトリ名: diff_<ファイル名>_<base>-to-<changed>
BASE_SHORT=$(echo "$BASE_VERSION" | sed 's/[^a-zA-Z0-9._-]/_/g')
CHANGED_SHORT=$(echo "$CHANGED_VERSION" | sed 's/[^a-zA-Z0-9._-]/_/g')
WORK_DIR="build/diff_$(basename ${TARGET_FILE%.*})_${BASE_SHORT}-to-${CHANGED_SHORT}"
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

# 画像ファイルの抽出関数（新旧両バージョン対応）
extract_image_files() {
    local version="$1"
    local target_dir="$2"
    local version_label="$3"  # "old" または "new"

    log_info "  $version から画像ファイルを抽出中... ($version_label)"

    # 画像ファイルの拡張子
    git ls-tree -r --name-only "$version" | grep -E '\.(png|jpg|jpeg|pdf|eps|svg)$' | while read -r file; do
        # src/ プレフィックスを除去して、作業ディレクトリに直接配置
        local relative_file="$file"
        if [[ "$file" == src/* ]]; then
            relative_file="${file#src/}"
        fi

        local target_file="$target_dir/$relative_file"
        local target_dirname=$(dirname "$target_file")

        mkdir -p "$target_dirname"
        if git show "$version:$file" > "$target_file" 2>/dev/null; then
            # 画像ファイルのold/new比較用にもコピー
            local img_basename=$(basename "$file")
            local img_ext="${img_basename##*.}"
            local img_name="${img_basename%.*}"

            mkdir -p "$WORK_DIR/diff-img/$version_label"
            cp "$target_file" "$WORK_DIR/diff-img/$version_label/"
        fi
    done
}

# ファイル抽出実行
extract_latex_files "$BASE_VERSION" "$WORK_DIR/base"
extract_latex_files "$CHANGED_VERSION" "$WORK_DIR/changed"

# 画像ファイルは新旧両バージョンを抽出
extract_image_files "$BASE_VERSION" "$WORK_DIR" "old"
extract_image_files "$CHANGED_VERSION" "$WORK_DIR" "new"

# ソースディレクトリのスタイルファイル等もコピー
log_info "  ソースディレクトリのファイルをコピー中..."
REPO_ROOT="$(git rev-parse --show-toplevel)"
for ext in "sty" "cls" "bib"; do
    find "$REPO_ROOT/$SRC_DIR" -maxdepth 1 -name "*.$ext" -exec cp {} "$WORK_DIR/" \; 2>/dev/null || true
done

# bibliographyディレクトリもコピー（ソースディレクトリから）
if [ -d "$REPO_ROOT/$SRC_DIR/bibliography" ]; then
    log_info "  bibliographyディレクトリをコピー中..."
    cp -r "$REPO_ROOT/$SRC_DIR/bibliography" "$WORK_DIR/"
fi

# メインファイルの存在確認
if [ ! -f "$WORK_DIR/base/$TARGET_FILE" ]; then
    log_error "比較元バージョンにターゲットファイル '$TARGET_FILE' が見つかりません"
    exit 1
fi

if [ ! -f "$WORK_DIR/changed/$TARGET_FILE" ]; then
    log_error "比較先バージョンにターゲットファイル '$TARGET_FILE' が見つかりません"
    exit 1
fi

# 3. ソースの平坦化
log_info "ソースファイルを平坦化中..."

# 平坦化実行
log_info "  作業ディレクトリ: $(pwd)"
cd "$WORK_DIR/base/$SRC_DIR"
log_info "  比較元バージョンを平坦化中... (現在: $(pwd))"
latexpand "$MAIN_TEX_NAME" > "../../main-base.tex"

cd "../../changed/$SRC_DIR"
log_info "  比較先バージョンを平坦化中... (現在: $(pwd))"
latexpand "$MAIN_TEX_NAME" > "../../main-changed.tex"

cd "../.."
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

# 現在のディレクトリを保存
CURRENT_DIR=$(pwd)
REPO_ROOT="$(git rev-parse --show-toplevel)"

# ソースディレクトリの.latexmkrcを使用（絶対パスで）
if [ -f "$REPO_ROOT/$SRC_DIR/.latexmkrc" ]; then
    cp "$REPO_ROOT/$SRC_DIR/.latexmkrc" .
    log_info "ソースディレクトリの.latexmkrcを使用: $SRC_DIR/.latexmkrc"

    # 出力ディレクトリ設定を現在のディレクトリ用に修正
    sed -i "s|\$out_dir = '../build'|\$out_dir = '.'|" .latexmkrc
elif [ -f "$REPO_ROOT/.latexmkrc" ]; then
    cp "$REPO_ROOT/.latexmkrc" .
    log_info "ワークスペースルートの.latexmkrcを使用"

    # 出力ディレクトリ設定を現在のディレクトリ用に修正
    sed -i "s|\$out_dir = '../build'|\$out_dir = '.'|" .latexmkrc
else
    log_warning ".latexmkrcが見つかりません。LuaLaTeXでの直接コンパイルを試行します"
    # .latexmkrcがない場合は、LuaLaTeXを直接使用
    lualatex -interaction=nonstopmode main-diff.tex

    if [ ! -f "main-diff.pdf" ]; then
        log_error "PDFコンパイルに失敗しました"
        log_info "詳細なエラーログを確認してください: $WORK_DIR/main-diff.log"
        exit 1
    fi

    log_success "PDFコンパイル完了: main-diff.pdf"
    return 0
fi

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

# 6. 詳細な変更ファイル分析
log_info "詳細な変更ファイル分析を実行中..."

# 分析関数: ファイル種別ごとの差分検出
analyze_file_changes() {
    local base_ver="$1"
    local changed_ver="$2"
    local work_dir="$3"

    # 現在のディレクトリを保存
    local original_dir=$(pwd)

    log_info "ファイル種別ごとの変更分析を開始..."

    # Git差分の全体を取得
    cd "$(git rev-parse --show-toplevel)"

    # 1. styファイルの変更検出
    local changed_sty=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.sty$' || true)
    if [ -n "$changed_sty" ]; then
        log_warning "変更されたスタイルファイル(.sty):"
        echo "$changed_sty" | while read -r file; do
            echo "  - $file"
        done

        mkdir -p "$work_dir/diff-styles"
        echo "$changed_sty" | while read -r file; do
            local basename_file=$(basename "$file")
            git show "$base_ver:$file" > "$work_dir/diff-styles/${basename_file}.old" 2>/dev/null || true
            git show "$changed_ver:$file" > "$work_dir/diff-styles/${basename_file}.new" 2>/dev/null || true
        done

        # styファイル専用のgit diff
        git diff "$base_ver" "$changed_ver" -- $(echo "$changed_sty" | tr '\n' ' ') > "$work_dir/git-diff-styles.diff"
        log_info "スタイルファイル差分を diff-styles/ と git-diff-styles.diff に保存"
    else
        log_info "スタイルファイル(.sty)に変更はありません"
    fi

    # 2. clsファイルの変更検出
    local changed_cls=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.cls$' || true)
    if [ -n "$changed_cls" ]; then
        log_warning "変更されたクラスファイル(.cls):"
        echo "$changed_cls" | while read -r file; do
            echo "  - $file"
        done

        mkdir -p "$work_dir/diff-classes"
        echo "$changed_cls" | while read -r file; do
            local basename_file=$(basename "$file")
            git show "$base_ver:$file" > "$work_dir/diff-classes/${basename_file}.old" 2>/dev/null || true
            git show "$changed_ver:$file" > "$work_dir/diff-classes/${basename_file}.new" 2>/dev/null || true
        done

        # clsファイル専用のgit diff
        git diff "$base_ver" "$changed_ver" -- $(echo "$changed_cls" | tr '\n' ' ') > "$work_dir/git-diff-classes.diff"
        log_info "クラスファイル差分を diff-classes/ と git-diff-classes.diff に保存"
    else
        log_info "クラスファイル(.cls)に変更はありません"
    fi

    # 3. texファイルの変更検出（詳細分析）
    local changed_tex=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.tex$' || true)
    if [ -n "$changed_tex" ]; then
        log_warning "変更されたTeXファイル(.tex):"
        echo "$changed_tex" | while read -r file; do
            echo "  - $file"
        done

        # texファイル専用のgit diff
        git diff "$base_ver" "$changed_ver" -- $(echo "$changed_tex" | tr '\n' ' ') > "$work_dir/git-diff-tex.diff"
        log_info "TeXファイル差分を git-diff-tex.diff に保存"
    else
        log_info "TeXファイル(.tex)に変更はありません"
    fi

    # 4. bibファイルの変更検出（既存機能の強化）
    local changed_bibs=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.bib$' || true)
    if [ -n "$changed_bibs" ]; then
        log_warning "変更された参考文献ファイル(.bib):"
        echo "$changed_bibs" | while read -r file; do
            echo "  - $file"
        done

        mkdir -p "$work_dir/diff-bib"
        echo "$changed_bibs" | while read -r file; do
            local basename_file=$(basename "$file")
            git show "$base_ver:$file" > "$work_dir/diff-bib/${basename_file}.old" 2>/dev/null || true
            git show "$changed_ver:$file" > "$work_dir/diff-bib/${basename_file}.new" 2>/dev/null || true
        done

        # bibファイル専用のgit diff
        git diff "$base_ver" "$changed_ver" -- $(echo "$changed_bibs" | tr '\n' ' ') > "$work_dir/git-diff-bib.diff"
        log_info "参考文献ファイル差分を diff-bib/ と git-diff-bib.diff に保存"
    else
        log_info "参考文献ファイル(.bib)に変更はありません"
    fi

    # 5. 画像ファイルの変更検出（強化版）
    local changed_images=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.(png|jpg|jpeg|pdf|eps|svg)$' || true)
    if [ -n "$changed_images" ]; then
        log_warning "変更された画像ファイル:"
        echo "$changed_images" | while read -r file; do
            echo "  - $file"
        done

        # 画像変更の詳細分析
        mkdir -p "$work_dir/diff-img-analysis"
        echo "$changed_images" | while read -r file; do
            local basename_file=$(basename "$file")

            # ファイルの変更種別を判定
            if git show "$base_ver:$file" > /dev/null 2>&1; then
                if git show "$changed_ver:$file" > /dev/null 2>&1; then
                    echo "MODIFIED: $file" >> "$work_dir/diff-img-analysis/changes.log"
                else
                    echo "DELETED: $file" >> "$work_dir/diff-img-analysis/changes.log"
                fi
            else
                echo "ADDED: $file" >> "$work_dir/diff-img-analysis/changes.log"
            fi
        done

        log_info "画像ファイル変更詳細を diff-img/ (old/new) と diff-img-analysis/ に保存"
    else
        log_info "画像ファイルに変更はありません"
    fi

    # 6. 全体のLaTeX関連ファイル差分（統合版）
    local all_latex_files=$(git diff --name-only "$base_ver" "$changed_ver" | grep -E '\.(tex|bib|cls|sty)$' || true)
    if [ -n "$all_latex_files" ]; then
        git diff "$base_ver" "$changed_ver" -- $(echo "$all_latex_files" | tr '\n' ' ') > "$work_dir/git-diff-all-latex.diff"
        log_info "全LaTeX関連ファイル統合差分を git-diff-all-latex.diff に保存"
    fi

    # 元のディレクトリに戻る
    cd "$original_dir"
}

# 変更ファイル分析を実行
analyze_file_changes "$BASE_VERSION" "$CHANGED_VERSION" "$WORK_DIR"

# 作業ディレクトリに確実に戻る（分析関数でcd移動しているため）
cd "$WORK_DIR"

# ファイルサイズ情報
PDF_SIZE=$(du -h main-diff.pdf | cut -f1)

# 一時ファイルの削除（確認すべきファイルのみ残す）
log_info "一時ファイルを削除中..."

# 削除するディレクトリ・ファイル
rm -rf base/ changed/ src/ figures/ bibliography/
rm -f RSL_style.sty main-base.tex main-changed.tex .latexmkrc
rm -f main-diff.aux main-diff.bbl main-diff.blg main-diff.fdb_latexmk main-diff.fls main-diff.log main-diff.out main-diff.toc

log_info "一時ファイルを削除しました"

# 最終報告
log_success "差分PDF生成が完了しました！"
log_info "=== 生成されたファイルとディレクトリ ==="
log_info "📄 差分PDF: $(pwd)/main-diff.pdf ($PDF_SIZE)"
log_info "📄 差分TeX: $(pwd)/main-diff.tex"

# ファイル種別ごとの出力を報告
if [ -f "git-diff-all-latex.diff" ]; then
    DIFF_SIZE=$(du -h git-diff-all-latex.diff | cut -f1)
    log_info "📄 全LaTeX差分: $(pwd)/git-diff-all-latex.diff ($DIFF_SIZE)"
fi

if [ -f "git-diff-tex.diff" ]; then
    TEX_DIFF_SIZE=$(du -h git-diff-tex.diff | cut -f1)
    log_info "📄 TeXファイル差分: $(pwd)/git-diff-tex.diff ($TEX_DIFF_SIZE)"
fi

if [ -f "git-diff-styles.diff" ]; then
    STY_DIFF_SIZE=$(du -h git-diff-styles.diff | cut -f1)
    log_info "🎨 スタイルファイル差分: $(pwd)/git-diff-styles.diff ($STY_DIFF_SIZE)"
fi

if [ -f "git-diff-classes.diff" ]; then
    CLS_DIFF_SIZE=$(du -h git-diff-classes.diff | cut -f1)
    log_info "📋 クラスファイル差分: $(pwd)/git-diff-classes.diff ($CLS_DIFF_SIZE)"
fi

if [ -f "git-diff-bib.diff" ]; then
    BIB_DIFF_SIZE=$(du -h git-diff-bib.diff | cut -f1)
    log_info "📚 参考文献差分: $(pwd)/git-diff-bib.diff ($BIB_DIFF_SIZE)"
fi

if [ -d "diff-img/old" ] && [ -d "diff-img/new" ]; then
    OLD_COUNT=$(find diff-img/old -type f 2>/dev/null | wc -l)
    NEW_COUNT=$(find diff-img/new -type f 2>/dev/null | wc -l)
    log_info "🖼️  画像ファイル比較:"
    log_info "   📁 変更前: $(pwd)/diff-img/old/ (${OLD_COUNT}個)"
    log_info "   📁 変更後: $(pwd)/diff-img/new/ (${NEW_COUNT}個)"
fi

if [ -d "diff-img-analysis" ]; then
    log_info "🔍 画像変更詳細: $(pwd)/diff-img-analysis/"
fi

if [ -d "diff-styles" ]; then
    STY_COUNT=$(find diff-styles -name "*.old" 2>/dev/null | wc -l)
    log_info "🎨 スタイルファイル比較: $(pwd)/diff-styles/ (${STY_COUNT}ファイル, .old/.new)"
fi

if [ -d "diff-classes" ]; then
    CLS_COUNT=$(find diff-classes -name "*.old" 2>/dev/null | wc -l)
    log_info "📋 クラスファイル比較: $(pwd)/diff-classes/ (${CLS_COUNT}ファイル, .old/.new)"
fi

if [ -d "diff-bib" ]; then
    BIB_COUNT=$(find diff-bib -name "*.old" 2>/dev/null | wc -l)
    log_info "📚 参考文献比較: $(pwd)/diff-bib/ (${BIB_COUNT}ファイル, .old/.new)"
fi

log_info "=== バージョン情報 ==="
log_info "📋 比較元バージョン: $BASE_VERSION"
log_info "📋 比較先バージョン: $CHANGED_VERSION"
log_info "📁 出力ディレクトリ: $(basename "$WORK_DIR")"

log_success "🎉 処理完了！差分PDFは $WORK_DIR/main-diff.pdf に保存されました"
