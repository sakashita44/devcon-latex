#!/bin/bash

# Git-LaTeX 差分PDF生成スクリプト (改良版)
# 仕様: 2つのGitバージョン間のLaTeX差分PDFを生成
# v2アプローチ: 完全なsrcディレクトリ構造を再現してPDF生成

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

# DVC管理ファイルの復元関数
restore_dvc_files() {
    local version="$1"
    local work_dir="$2"
    local version_name="$3"

    log_info "  $version_name でDVC管理ファイルを復元中..."

    # 現在のブランチを保存
    local current_branch=$(git branch --show-current)
    local current_commit=$(git rev-parse HEAD)

    # 一時的にターゲットバージョンにチェックアウト
    git checkout "$version" --quiet

    # DVCファイルが存在するかチェック
    if [ -f ".dvc/config" ] && find . -name "*.dvc" -type f | head -1 | grep -q .; then
        log_info "    DVC管理ファイルを復元中..."
        if dvc checkout --quiet 2>/dev/null; then
            log_success "    DVC復元完了"
        else
            log_warning "    DVC復元に失敗（一部ファイルが不足している可能性）"
        fi

        # DVC管理ファイルをwork_dirにコピー（srcプレフィックスを除去）
        find src -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.pdf" -o -name "*.eps" -o -name "*.svg" | while read -r file; do
            local relative_file="${file#src/}"
            local target_file="$work_dir/$relative_file"
            local target_dir=$(dirname "$target_file")
            mkdir -p "$target_dir"
            cp "$file" "$target_file" 2>/dev/null || true
        done
    else
        log_info "    DVCファイルなし、git履歴から画像を復元"
        # git show で画像ファイルを復元（srcプレフィックスを除去）
        git ls-tree -r --name-only "$version" | grep -E '\.(png|jpg|jpeg|pdf|eps|svg)$' | grep "^src/" | while read -r file; do
            local relative_file="${file#src/}"
            local target_file="$work_dir/$relative_file"
            local target_dir=$(dirname "$target_file")
            mkdir -p "$target_dir"
            git show "$version:$file" > "$target_file" 2>/dev/null || true
        done
    fi

    # 元のコミットに戻る
    if [ -n "$current_branch" ]; then
        git checkout "$current_branch" --quiet
    else
        git checkout "$current_commit" --quiet
    fi
}

# 完全なsrcディレクトリ構造の復元関数
restore_full_src() {
    local version="$1"
    local target_dir="$2"
    local version_name="$3"

    log_info "$version_name のsrcディレクトリ構造を復元中..."

    # すべてのsrc配下ファイルを復元（srcプレフィックスを除去して直接配置）
    git ls-tree -r --name-only "$version" | grep "^src/" | while read -r file; do
        # src/ プレフィックスを除去
        local relative_file="${file#src/}"
        local target_file="$target_dir/$relative_file"
        local target_dirname=$(dirname "$target_file")

        mkdir -p "$target_dirname"
        if git show "$version:$file" > "$target_file" 2>/dev/null; then
            log_info "  復元: $relative_file"
        else
            log_warning "  復元失敗: $file"
        fi
    done

    # DVC管理ファイルの復元
    restore_dvc_files "$version" "$target_dir" "$version_name"
}

# latexpandでファイルを平坦化する関数
create_flat_tex() {
    local src_dir="$1"
    local main_tex_path="$2"
    local output_file="$3"
    local version_name="$4"

    log_info "$version_name の平坦化ファイルを作成中..."

    # メインファイルのディレクトリに移動してlatexpandを実行
    # src/プレフィックスを除去済みなので、直接パスを使用
    local main_dir="$src_dir/$(dirname "$main_tex_path")"
    local main_file=$(basename "$main_tex_path")
    local abs_output_file=$(realpath "$output_file")

    log_info "  作業ディレクトリ: $main_dir"
    log_info "  メインファイル: $main_file"
    log_info "  出力ファイル: $abs_output_file"

    cd "$main_dir"
    if latexpand "$main_file" > "$abs_output_file" 2>/dev/null; then
        log_success "  平坦化完了: $abs_output_file"
    else
        log_error "  平坦化失敗: $main_tex_path"
        return 1
    fi
    cd - > /dev/null
}

# 1. 初期化
log_info "Git-LaTeX差分PDF生成を開始します（改良版）..."

# 引数チェック
if [ $# -ne 3 ]; then
    log_error "引数が不足しています"
    show_usage
    exit 1
fi

TARGET_FILE="$1"
BASE_VERSION="$2"
CHANGED_VERSION="$3"

# リポジトリルートを取得
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# パラメータ解析
SRC_DIR="$(dirname "$TARGET_FILE")"
MAIN_TEX_NAME="$(basename "$TARGET_FILE")"
TARGET_REL_PATH="${TARGET_FILE#src/}"  # src/プレフィックスを除去

log_info "設定:"
log_info "  ターゲットファイル: $TARGET_FILE"
log_info "  相対パス: $TARGET_REL_PATH"
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

# 作業用ディレクトリの設定
BASE_SHORT=$(echo "$BASE_VERSION" | sed 's/[^a-zA-Z0-9._-]/_/g')
CHANGED_SHORT=$(echo "$CHANGED_VERSION" | sed 's/[^a-zA-Z0-9._-]/_/g')
TARGET_BASE_NAME=$(basename "${TARGET_FILE%.*}")
WORK_DIR="build/diff/${TARGET_BASE_NAME}_${BASE_SHORT}-to-${CHANGED_SHORT}"

log_info "作業用ディレクトリ: $WORK_DIR"

# 既存の作業ディレクトリを削除
if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

# 作業ディレクトリ構造を作成
mkdir -p "$WORK_DIR/base"
mkdir -p "$WORK_DIR/changed"

# 2. ファイル復元と画像差分機能
log_info "ファイルを復元中..."

# 画像ファイルの差分用抽出関数（元の機能を維持）
extract_image_files_for_diff() {
    local version="$1"
    local target_dir="$2"
    local version_label="$3"  # "old" または "new"

    log_info "  $version から画像ファイルを差分用に抽出中... ($version_label)"

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

# v2のsrcディレクトリ完全復元
log_info "=== ステップ3: baseバージョンの復元 ==="
restore_full_src "$BASE_VERSION" "$WORK_DIR/base" "base"

log_info "=== ステップ4: changedバージョンの復元 ==="
restore_full_src "$CHANGED_VERSION" "$WORK_DIR/changed" "changed"

# 画像差分機能（元のスクリプトの機能を維持）
extract_image_files_for_diff "$BASE_VERSION" "$WORK_DIR" "old"
extract_image_files_for_diff "$CHANGED_VERSION" "$WORK_DIR" "new"

# ソースディレクトリのスタイルファイル等もコピー（後方互換性のため）
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

# 3. ソースの平坦化（v2アプローチ）
log_info "=== ステップ5: 平坦化ファイル作成 ==="
cd "$WORK_DIR"
create_flat_tex "$WORK_DIR/base" "$TARGET_REL_PATH" "$WORK_DIR/main-base.tex" "base"
create_flat_tex "$WORK_DIR/changed" "$TARGET_REL_PATH" "$WORK_DIR/main-changed.tex" "changed"

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
log_info "=== ステップ6: 差分ファイル生成 ==="

latexdiff main-base.tex main-changed.tex > main-diff.tex

if [ ! -f "main-diff.tex" ] || [ ! -s "main-diff.tex" ]; then
    log_error "差分ファイルの生成に失敗しました"
    exit 1
fi

log_success "差分ファイル生成完了: main-diff.tex"

# 5. v2アプローチによるPDFコンパイル
log_info "=== ステップ7: 差分ファイル配置 ==="
TARGET_DIR="changed/$(dirname "$TARGET_REL_PATH")"
mkdir -p "$TARGET_DIR"
cp main-diff.tex "$TARGET_DIR/$(basename "$TARGET_REL_PATH")"
log_success "差分ファイル配置完了: $TARGET_DIR/$(basename "$TARGET_REL_PATH")"

# .latexmkrcファイルも同じ場所にコピー
LATEXMKRC_SOURCE="changed/$(dirname "$TARGET_REL_PATH")/.latexmkrc"
if [ -f "$LATEXMKRC_SOURCE" ] && [ "$LATEXMKRC_SOURCE" != "$TARGET_DIR/.latexmkrc" ]; then
    cp "$LATEXMKRC_SOURCE" "$TARGET_DIR/"
    log_info ".latexmkrcファイルもコピーしました"
fi

log_info "=== ステップ8: 差分PDFビルド ==="
DIFF_TEX_PATH="$TARGET_DIR/$(basename "$TARGET_REL_PATH")"
ABS_DIFF_TEX_PATH=$(realpath "$DIFF_TEX_PATH")
cd "$(dirname "$ABS_DIFF_TEX_PATH")"

# .latexmkrcファイルが存在するかチェック
if [ -f ".latexmkrc" ]; then
    log_info "latexmkrcファイルを使用してビルド実行"
    if latexmk "$(basename "$TARGET_REL_PATH")"; then
        log_success "PDFビルド完了"

        # 生成されたPDFファイルの場所を確認・報告
        find . -name "*.pdf" -newer "$(basename "$TARGET_REL_PATH")" 2>/dev/null | while read -r pdf_file; do
            local abs_path=$(realpath "$pdf_file")
            log_success "生成されたPDF: $abs_path"
        done

        # ビルドディレクトリ内のPDFも探す
        find ../../build -name "*.pdf" -newer "$(basename "$TARGET_REL_PATH")" 2>/dev/null | while read -r pdf_file; do
            local abs_path=$(realpath "$pdf_file")
            log_success "ビルドディレクトリ内のPDF: $abs_path"
        done
    else
        log_warning "PDFビルドでエラーが発生しましたが、処理を続行します"
    fi
else
    log_warning ".latexmkrcファイルが見つかりません。手動でビルドしてください"
    log_info "ビルド対象ファイル: $ABS_DIFF_TEX_PATH"
fi

cd "$REPO_ROOT/$WORK_DIR"

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

# PDFファイルサイズを取得（v2アプローチの場合は複数箇所に存在する可能性）
PDF_SIZE=""
if [ -f "main-diff.pdf" ]; then
    PDF_SIZE=$(du -h main-diff.pdf | cut -f1)
elif [ -f "../../build/jp/main.pdf" ]; then
    PDF_SIZE=$(du -h ../../build/jp/main.pdf | cut -f1)
    log_info "PDFは ../../build/jp/main.pdf に生成されました"
fi

# 一時ファイルの削除（確認すべきファイルのみ残す）
log_info "一時ファイルを削除中..."

# v2アプローチ用の一時ファイル削除
rm -rf base/ changed/
rm -f main-base.tex main-changed.tex .latexmkrc
# その他の一時ファイル（build配下は残す）
find . -maxdepth 1 -name "*.aux" -o -name "*.bbl" -o -name "*.blg" -o -name "*.fdb_latexmk" -o -name "*.fls" -o -name "*.log" -o -name "*.out" -o -name "*.toc" | xargs rm -f 2>/dev/null || true

log_info "一時ファイルを削除しました"

# 最終報告
log_success "差分PDF生成が完了しました！"
log_info "=== 生成されたファイルとディレクトリ ==="

# PDFファイルの場所を正確に報告
if [ -f "main-diff.pdf" ]; then
    log_info "📄 差分PDF: $(pwd)/main-diff.pdf ($PDF_SIZE)"
elif [ -f "../../build/jp/main.pdf" ]; then
    log_info "📄 差分PDF: $(realpath ../../build/jp/main.pdf) ($PDF_SIZE)"
elif [ -f "build/jp/main.pdf" ]; then
    log_info "📄 差分PDF: $(realpath build/jp/main.pdf) ($PDF_SIZE)"
else
    # PDFを探す
    PDF_FOUND=$(find . -name "*.pdf" -type f | head -1)
    if [ -n "$PDF_FOUND" ]; then
        PDF_SIZE=$(du -h "$PDF_FOUND" | cut -f1)
        log_info "📄 差分PDF: $(realpath "$PDF_FOUND") ($PDF_SIZE)"
    else
        log_warning "PDFファイルが見つかりませんでした"
    fi
fi

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

# 最終成功メッセージでPDFの場所を正確に伝える
if [ -f "main-diff.pdf" ]; then
    log_success "🎉 処理完了！差分PDFは $WORK_DIR/main-diff.pdf に保存されました"
elif [ -f "../../build/jp/main.pdf" ]; then
    log_success "🎉 処理完了！差分PDFは $(realpath ../../build/jp/main.pdf) に保存されました"
elif [ -f "build/jp/main.pdf" ]; then
    log_success "🎉 処理完了！差分PDFは $(realpath build/jp/main.pdf) に保存されました"
else
    PDF_FOUND=$(find . -name "*.pdf" -type f | head -1)
    if [ -n "$PDF_FOUND" ]; then
        log_success "🎉 処理完了！差分PDFは $(realpath "$PDF_FOUND") に保存されました"
    else
        log_success "🎉 処理完了！（PDFの生成でエラーがありましたが、差分ファイルは生成されました）"
        log_info "差分TeXファイル: $WORK_DIR/main-diff.tex"
    fi
fi
