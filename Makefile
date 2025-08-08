# LaTeX論文差分計算用Makefile

.PHONY: diff diff-pdf clean help test-tag build watch

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  make build      - LaTeX文書をビルド (main.tex)"
	@echo "  make watch      - ファイル変更を監視して自動ビルド"
	@echo "  make diff       - 直前の変更を表示"
	@echo "  make diff-pdf   - 指定されたバージョン間の視覚的差分PDFを生成"
	@echo "  make test-tag   - テスト用のタグを作成"
	@echo "  make clean      - 出力ファイルをクリーンアップ"
	@echo "  make help       - このヘルプを表示"
	@echo ""
	@echo "差分PDF生成の使用例:"
	@echo "  make diff-pdf BASE=v1.0.0 CHANGED=test"
	@echo "  make diff-pdf BASE=HEAD~1 CHANGED=HEAD"

# LaTeX文書ビルド
build:
	@echo "LaTeX文書をビルド中..."
	@latexmk main.tex
	@echo "ビルド完了: main.pdf"

# ファイル変更監視ビルド
watch:
	@echo "ファイル変更監視モード開始..."
	@echo "Ctrl+C で停止"
	@latexmk -pvc main.tex

# Git差分表示
diff:
	@echo "現在の変更を表示中..."
	@git diff HEAD~1..HEAD

# 視覚的差分PDF生成
diff-pdf:
	@if [ -z "$(BASE)" ] || [ -z "$(CHANGED)" ]; then \
		echo "エラー: BASE と CHANGED パラメータが必要です"; \
		echo "使用例: make diff-pdf BASE=v1.0.0 CHANGED=test"; \
		exit 1; \
	fi
	@echo "差分PDF生成中: $(BASE) → $(CHANGED)"
	@./scripts/generate_diff.sh main.tex $(BASE) $(CHANGED)

# テスト用タグ作成
test-tag:
	@echo "現在のタグ:"
	@git tag
	@echo ""
	@read -p "新しいタグ名 (例: v2.0): " tag_name; \
	read -p "タグメッセージ (例: Second version for review): " tag_message; \
	git tag -a "$$tag_name" -m "$$tag_message"; \
	echo "タグ '$$tag_name' を作成しました"

# クリーンアップ
clean:
	@echo "出力ファイルをクリーンアップ中..."
	@latexmk -C
	@rm -rf diff_output
	@echo "クリーンアップ完了"
