# LaTeX差分計算ツール リファレンス

LaTeX論文のバージョン間差分を自動計算するコンテナ内ツールです。

## 重要な設定ファイル

### .latexmkrc設定

差分PDF生成では **ルートディレクトリの `.latexmkrc`** の設定を参照してPDFコンパイルを実行します:

```ini
$pdf_mode = 4;  # LuaLaTeX使用
$lualatex = 'lualatex -interaction=nonstopmode %O %S';
$bibtex_use = 2;  # BibTeX有効
```

**エンジンを変更した場合（upLaTeX, pdfLaTeX等）は、差分PDF生成が正常に動作するよう `.latexmkrc` を適切に調整してください。**

## 機能概要

- **Git差分**: タグ間のソースコード差分をテキスト形式で出力
- **LaTeX差分**: latexdiffを使用した視覚的差分をPDF形式で出力
- **視覚的差分PDF**: 完全にコンパイルされた差分PDFの生成（推奨）
- **自動ファイル結合**: `\include`と`\input`コマンドを展開して単一ファイルに変換
- **参考文献対応**: BibTeX処理と参考文献の変更検出

## クイックスタート

```bash
# タグを作成
git tag -a v2.0 -m "Second version for review"

# 視覚的差分PDFを生成（推奨）
make diff-pdf BASE=v1.0.0 CHANGED=v2.0

# 従来の差分計算
make diff

# 結果を確認
ls diff_output/
```

## コマンドリファレンス

### make コマンド

```bash
make help                              # ヘルプ表示
make diff                              # 従来の差分計算実行
make diff-pdf BASE=v1.0.0 CHANGED=v2.0  # 視覚的差分PDF生成
make test-tag                          # 対話式タグ作成
make clean                             # 出力ディレクトリクリーンアップ
```

### 視覚的差分PDF生成の使用例

```bash
# タグ間の差分
make diff-pdf BASE=v1.0.0 CHANGED=test

# コミット間の差分
make diff-pdf BASE=HEAD~1 CHANGED=HEAD

# ブランチ間の差分
make diff-pdf BASE=main CHANGED=feature-branch
```

### 直接実行

```bash
# 視覚的差分PDF生成スクリプト
./scripts/generate_diff.sh main.tex v1.0.0 test

# 従来の差分表示
make diff

# 特定のタグ間差分（手動Git差分）
git diff v1.0 v2.0
```

## 出力ファイル

### 視覚的差分PDF生成 (`make diff-pdf`)

`diff_output/`ディレクトリに以下のファイルが生成されます:

- `main-diff.pdf`: **完全にコンパイルされた差分PDF** (推奨確認ファイル)
- `main-diff.tex`: latexdiffで生成された差分ソースファイル
- `git-diff.diff`: LaTeX関連ファイルのGit差分（シンタックスハイライト対応）
- `diff-img/`: 変更された画像ファイル（存在する場合）
- `diff-bib/`: 変更された参考文献ファイル（`.old`/`.new`で比較可能）

### 従来の差分計算 (`make diff`)

現在の変更内容を表示します:

```bash
git diff HEAD~1..HEAD
```

## 技術仕様

### ファイル結合方式

スクリプトは以下の方式でファイル結合を実行:

1. **latexpand**: LaTeX専用展開ツールを使用して `\include`/`\input` を再帰的に展開

### コンパイル環境

- **エンジン**: LuaLaTeX（`.latexmkrc`設定による）
- **ビルドシステム**: latexmk（自動的な依存関係解決）
- **対応クラス**: `ltjsbook`, `ltjsarticle`, `article`, `book`
- **フォント**: 日本語フォント自動選択

## システム要件

### 必要なツール

コンテナ内に以下がインストール済み:

- Git
- LaTeX（LuaLaTeX対応）
- latexdiff
- latexpand
- latexmk

### 対応文書クラス

- 日本語文書クラス（`ltjsbook`, `ltjsarticle`等）
- 欧文文書クラス（`article`, `book`等）

## トラブルシューティング

### PDFコンパイルエラー

| 症状             | 原因                  | 対処法                         |
| ---------------- | --------------------- | ------------------------------ |
| フォントエラー   | `.latexmkrc`設定問題  | `.latexmkrc`のエンジン設定確認 |
| パッケージエラー | 不足パッケージ        | コンテナ環境確認               |
| コンパイル失敗   | TeXファイル構文エラー | `main-diff.tex`を手動確認      |

### ファイル結合エラー

| 症状               | 原因             | 対処法               |
| ------------------ | ---------------- | -------------------- |
| `\include`展開失敗 | ファイルパス問題 | 相対パス確認         |
| latexpand変換失敗  | 複雑な構造       | ファイル構造の簡略化 |
| 画像参照エラー     | 絶対パス使用     | 相対パス使用         |

### デバッグ方法

```bash
# 詳細ログ確認（差分PDF生成）
cat diff_output/main-diff.log

# 手動コンパイルテスト
cd diff_output
latexmk main-diff.tex

# 段階的確認
make diff-pdf BASE=v1.0.0 CHANGED=test
```

## 高度な使用方法

### カスタムタグ範囲

```bash
# 手動でタグ範囲指定
git diff v1.5 v2.1 > custom_diff.txt
```

### バッチ処理

```bash
# 複数バージョン一括処理
for tag in v1.0 v2.0 v3.0; do
  git tag -a "${tag}.1" -m "Minor revision of $tag"
  make diff
  mv diff_output "diff_output_$tag"
done
```

## システム要件詳細

### 必須パッケージ

- `git` >= 2.0
- `latexdiff` >= 1.3.0
- `latexpand` (TeX Live付属)
- `latexmk` (TeX Live付属)
- LuaLaTeX (TeX Live 2020以降)

### 対応ファイル構造

```text
project/
├── main.tex          # メインファイル
├── chapters/          # \include対象
│   ├── chapter1.tex
│   └── chapter2.tex
├── figures/           # 図表ディレクトリ
└── bibliography/      # 参考文献
```

## ワークフロー統合

詳細な論文執筆ワークフローについては [`workflow.md`](workflow.md) を参照してください。

## 制限事項と既知の問題

- 差分PDF生成には最低2つのGitバージョン（タグ・コミット・ブランチ）が必要
- 複雑な`\input`/`\include`ネスト構造では手動調整が必要な場合あり
- 図表ファイルは相対パスで記述する必要あり
- `\includeonly`コマンドは現在未対応
- 大量のファイルでは処理時間が長くなる場合あり
- エンジン変更時は`.latexmkrc`の適切な調整が必要
