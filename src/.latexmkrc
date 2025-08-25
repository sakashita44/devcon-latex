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

# フルコンパイル設定: lualatex -> bibtex -> lualatex -> lualatex
# latexmkが自動的に必要に応じて繰り返し実行する
