# LaTeX差分計算ツール リファレンス

LaTeX論文のバージョン間差分を自動計算するコンテナ内ツールです。

## 機能概要

- **Git差分**: タグ間のソースコード差分をテキスト形式で出力
- **LaTeX差分**: latexdiffを使用した視覚的差分をPDF形式で出力
- **自動ファイル結合**: `\include`と`\input`コマンドを展開して単一ファイルに変換

## クイックスタート

```bash
# タグを作成
git tag -a v2.0 -m "Second version for review"

# 差分を計算
make diff

# 結果を確認
ls diff_output/
```

## コマンドリファレンス

### make コマンド

```bash
make help      # ヘルプ表示
make diff      # 差分計算実行
make test-tag  # 対話式タグ作成
make clean     # 出力ディレクトリクリーンアップ
```

### 直接実行

```bash
# スクリプト直接実行
./scripts/calculate_diff.sh

# 特定のタグ間差分（手動Git差分）
git diff v1.0 v2.0
```

## 出力ファイル

差分計算により以下のファイルが`diff_output/`ディレクトリに生成されます:

- `git_diff.txt`: Git差分（テキスト形式）
- `diff.tex`: LaTeX差分ファイル（latexdiff生成）
- `diff.pdf`: 視覚的差分PDF（赤：削除、青：追加）
- `diff.log`: コンパイル詳細ログ

## 技術仕様

### ファイル結合方式

スクリプトは以下の順序でファイル結合を試行:

1. **pandoc**: 標準的なLaTeX変換ツール
2. **latexexpand**: LaTeX専用展開ツール
3. **カスタムPython**: `\include`/`\input`の再帰展開

### コンパイル環境

- **エンジン**: LuaLaTeX（日本語対応）
- **対応クラス**: `ltjsbook`, `ltjsarticle`, `article`, `book`
- **フォント**: 日本語フォント自動選択

## システム要件

### 必要なツール

コンテナ内に以下がインストール済み:

- Git
- LaTeX（LuaLaTeX対応）
- latexdiff
- pandoc
- Python 3

### 対応文書クラス

- 日本語文書クラス（`ltjsbook`, `ltjsarticle`等）
- 欧文文書クラス（`article`, `book`等）

## トラブルシューティング

### PDFコンパイルエラー

| 症状             | 原因                  | 対処法                     |
| ---------------- | --------------------- | -------------------------- |
| フォントエラー   | LuaLaTeX設定問題      | `lualatex`コマンド使用確認 |
| パッケージエラー | 不足パッケージ        | コンテナ環境確認           |
| コンパイル失敗   | TeXファイル構文エラー | `diff.tex`を手動確認       |

### ファイル結合エラー

| 症状               | 原因             | 対処法                       |
| ------------------ | ---------------- | ---------------------------- |
| `\include`展開失敗 | ファイルパス問題 | 相対パス確認                 |
| pandoc変換失敗     | 複雑な構造       | カスタムスクリプトで自動対応 |
| 画像参照エラー     | 絶対パス使用     | 相対パス使用                 |

### デバッグ方法

```bash
# 詳細ログ確認
cat diff_output/diff.log

# 手動コンパイルテスト
cd diff_output
lualatex diff.tex

# 段階的確認
./scripts/calculate_diff.sh 2>&1 | tee debug.log
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
- `lualatex` (TeX Live 2020以降)
- `pandoc` >= 2.0
- `python3` >= 3.6

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

- 差分計算には最低2つのタグが必要
- 複雑な`\input`/`\include`ネスト構造では手動調整が必要な場合あり
- 図表ファイルは相対パスで記述する必要あり
- `\includeonly`コマンドは現在未対応
- 大量のファイルでは処理時間が長くなる場合あり
