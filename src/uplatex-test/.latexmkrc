# uplatex版用の出力ディレクトリをbuild/uplatex/に設定
$out_dir = '../../build/uplatex';

# upLaTeX設定
$latex = 'uplatex -interaction=nonstopmode %O %S';
$pdflatex = 'uplatex -interaction=nonstopmode %O %S';
$bibtex = 'pbibtex %O %B';
$dvips = 'dvips %O -o %D %S';
$pdf_mode = 3;  # LaTeX -> DVI -> PDF (dvipdfmx)
$dvipdf = 'dvipdfmx %O -o %D %S';
$bibtex_use = 2;
$max_repeat = 5;  # 最大繰り返し回数

# 画像処理用extractbb設定
add_cus_dep('png', 'bb', 0, 'extractbb');
add_cus_dep('jpg', 'bb', 0, 'extractbb');
add_cus_dep('jpeg', 'bb', 0, 'extractbb');
sub extractbb {
    system("extractbb \"$_[0]\"");
}

# BibTeX設定
$ENV{'BIBINPUTS'} = '../bibliography/:' . ($ENV{'BIBINPUTS'} || '');

# クリーンアップ対象
$clean_ext = "aux bbl blg fdb_latexmk fls log nav out snm toc dvi bb";

# フルコンパイル設定: uplatex -> pbibtex -> uplatex -> uplatex -> dvipdfmx
# latexmkが自動的に必要に応じて繰り返し実行する
