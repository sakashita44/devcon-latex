#!/bin/bash

# LaTeX差分計算スクリプト
# 直前の2つのタグ間でGitの差分とlatexdiffによるPDF差分を生成

set -e

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

# 出力ディレクトリの作成
OUTPUT_DIR="diff_output"
mkdir -p "$OUTPUT_DIR"

log_info "差分計算を開始します..."

# 全タグを取得
log_info "利用可能なタグを確認中..."
git fetch --tags > /dev/null 2>&1 || true

TAGS=$(git tag --sort=-creatordate)
TAG_ARRAY=($TAGS)

if [ ${#TAG_ARRAY[@]} -lt 2 ]; then
    log_error "差分計算には最低2つのタグが必要です"
    log_info "現在のタグ: ${TAG_ARRAY[*]}"
    exit 1
fi

OLD_TAG=${TAG_ARRAY[1]}
NEW_TAG=${TAG_ARRAY[0]}

log_info "差分対象: $OLD_TAG -> $NEW_TAG"

# Git差分の生成
log_info "Git差分を生成中..."
git diff "$OLD_TAG" "$NEW_TAG" > "$OUTPUT_DIR/git_diff.txt"
log_success "Git差分を保存: $OUTPUT_DIR/git_diff.txt"

# 各タグのファイルをチェックアウトしてlatexdiff用に準備
log_info "LaTeX差分を生成中..."

# 一時ディレクトリの作成
TEMP_DIR=$(mktemp -d)
OLD_DIR="$TEMP_DIR/old"
NEW_DIR="$TEMP_DIR/new"
mkdir -p "$OLD_DIR" "$NEW_DIR"

# 旧バージョンのファイルを取得
log_info "旧バージョン ($OLD_TAG) のファイルを準備中..."
git archive "$OLD_TAG" | tar -x -C "$OLD_DIR"

# 新バージョンのファイルを取得
log_info "新バージョン ($NEW_TAG) のファイルを準備中..."
git archive "$NEW_TAG" | tar -x -C "$NEW_DIR"

# pandocを使用してファイルを単一のtexファイルに変換する関数
flatten_latex() {
    local input_dir="$1"
    local output_file="$2"
    local main_tex="$input_dir/main.tex"

    if [ ! -f "$main_tex" ]; then
        log_error "main.texが見つかりません: $main_tex"
        return 1
    fi

    log_info "pandocで単一ファイルに変換中: $input_dir -> $output_file"

    # pandocを使用してLaTeXファイルを単一ファイルに変換
    # --stand-alone: 完全なドキュメントとして出力
    # --from latex: 入力形式をLaTeXとして指定
    # --to latex: 出力形式をLaTeXとして指定
    cd "$input_dir"
    pandoc main.tex \
        --from latex \
        --to latex \
        --standalone \
        --output "$output_file" 2>/dev/null || {

        # pandocが失敗した場合は、latexexpandを試行
        log_warning "pandocが失敗しました。latexexpandを試行中..."
        if command -v latexexpand > /dev/null 2>&1; then
            latexexpand main.tex > "$output_file"
        else
            # latexexpandも利用できない場合は、シンプルな方法でファイルを結合
            log_warning "latexexpandも利用できません。シンプルな結合を実行中..."
            simple_flatten "$input_dir" "$output_file"
        fi
    }
}

# シンプルなファイル結合関数（フォールバック用）
simple_flatten() {
    local input_dir="$1"
    local output_file="$2"
    local main_tex="$input_dir/main.tex"

    # main.texを基に、\includeと\inputを再帰的に展開
    python3 - "$main_tex" "$input_dir" "$output_file" << 'EOF'
import re
import os
import sys

def expand_includes(content, base_dir):
    # \include{file}を展開
    def replace_include(match):
        file_path = match.group(1)
        if not file_path.endswith('.tex'):
            file_path += '.tex'

        full_path = os.path.join(base_dir, file_path)
        if os.path.exists(full_path):
            with open(full_path, 'r', encoding='utf-8') as f:
                included_content = f.read()
            return expand_includes(included_content, base_dir)
        else:
            return match.group(0)  # ファイルが見つからない場合は元のまま

    # \input{file}を展開
    def replace_input(match):
        file_path = match.group(1)
        if not file_path.endswith('.tex'):
            file_path += '.tex'

        full_path = os.path.join(base_dir, file_path)
        if os.path.exists(full_path):
            with open(full_path, 'r', encoding='utf-8') as f:
                included_content = f.read()
            return expand_includes(included_content, base_dir)
        else:
            return match.group(0)  # ファイルが見つからない場合は元のまま

    # \\includeパターンを展開（rawストリングを使用）
    content = re.sub(r'\\include\{([^}]+)\}', replace_include, content)
    # \\inputパターンを展開（rawストリングを使用）
    content = re.sub(r'\\input\{([^}]+)\}', replace_input, content)

    return content

# コマンドライン引数から取得
main_tex = sys.argv[1] if len(sys.argv) > 1 else 'main.tex'
input_dir = sys.argv[2] if len(sys.argv) > 2 else '.'
output_file = sys.argv[3] if len(sys.argv) > 3 else 'output.tex'

# main.texを読み込み
with open(main_tex, 'r', encoding='utf-8') as f:
    content = f.read()

# \includeと\inputを展開
expanded_content = expand_includes(content, input_dir)

# 結果を出力
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(expanded_content)
EOF
}

# 各バージョンを単一ファイルに変換
OLD_FLAT="$TEMP_DIR/old_flat.tex"
NEW_FLAT="$TEMP_DIR/new_flat.tex"

flatten_latex "$OLD_DIR" "$OLD_FLAT"
flatten_latex "$NEW_DIR" "$NEW_FLAT"

# latexdiffを実行
log_info "latexdiffを実行中..."
DIFF_TEX="$OUTPUT_DIR/diff.tex"
latexdiff "$OLD_FLAT" "$NEW_FLAT" > "$DIFF_TEX"
log_success "LaTeX差分ファイルを生成: $DIFF_TEX"

# PDFを生成（新バージョンのディレクトリで実行してリソースにアクセス）
log_info "差分PDFを生成中..."
cd "$NEW_DIR"
cp "$DIFF_TEX" ./diff.tex

# 必要に応じて複数回コンパイル
for i in {1..3}; do
    log_info "PDFコンパイル (${i}/3)..."
    pdflatex -interaction=nonstopmode diff.tex > /dev/null 2>&1 || {
        log_warning "PDFコンパイルでエラーが発生しました (試行 $i/3)"
        if [ $i -eq 3 ]; then
            log_error "PDFコンパイルに失敗しました"
        fi
    }
done

# PDFが生成された場合は出力ディレクトリにコピー
if [ -f "diff.pdf" ]; then
    cp "diff.pdf" "/workspaces/$OUTPUT_DIR/"
    log_success "差分PDFを生成: $OUTPUT_DIR/diff.pdf"
else
    log_warning "PDFの生成に失敗しました。TeXファイルは利用可能です: $DIFF_TEX"
fi

# 一時ディレクトリのクリーンアップ
cd /workspaces
rm -rf "$TEMP_DIR"

log_success "差分計算が完了しました"
log_info "出力ディレクトリ: $OUTPUT_DIR"
log_info "生成されたファイル:"
ls -la "$OUTPUT_DIR"
