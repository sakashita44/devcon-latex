# LaTeX論文差分計算用Makefile

.PHONY: diff clean help test-tag

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  make diff      - 直前の2つのタグ間の差分を計算"
	@echo "  make test-tag  - テスト用のタグを作成"
	@echo "  make clean     - 差分出力ディレクトリをクリーンアップ"
	@echo "  make help      - このヘルプを表示"

# 差分計算
diff:
	@echo "タグ間の差分を計算中..."
	@./scripts/calculate_diff.sh

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
	@echo "差分出力をクリーンアップ中..."
	@rm -rf diff_output
	@echo "クリーンアップ完了"
