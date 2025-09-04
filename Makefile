# LaTeX論文差分計算用Makefile

# 設定ファイルの読み込み（config を正とする）
# .config.mk は必須（missing -> make エラー）
$(shell bash ./scripts/gen_config_mk.sh config .config.mk >/dev/null 2>&1 || true)
ifneq ($(wildcard .config.mk),)
include .config.mk
else
$(error Missing .config.mk; generate it with: ./scripts/gen_config_mk.sh config .config.mk)
endif

# デフォルト設定（不足キーは .config.mk 側で定義されることを想定）
IMAGE_EXTENSIONS ?= png jpg jpeg pdf eps svg

# Make-level default (can be overridden on command line)
ifndef TARGET
TARGET := $(DEFAULT_TARGET)
endif
ifndef OUT
OUT := $(DEFAULT_OUT_DIR)
endif

# TARGET_BASE/TARGET_CHANGED の分解ロジック
# TARGET_BASE が未定義なら TARGET を使用、TARGET も未定義なら DEFAULT_TARGET を使用
ifndef TARGET_BASE
TARGET_BASE := $(TARGET)
endif
ifndef TARGET_CHANGED
TARGET_CHANGED := $(TARGET)
endif

# Resolve BASE/CHANGED at make parse time using helper script (falls back inside script)
RESOLVED := $(shell bash ./scripts/diff/resolve_refs.sh '$(or $(BASE),)' '$(or $(CHANGED),)')
RESOLVED_BASE := $(word 1,$(RESOLVED))
RESOLVED_CHANGED := $(wordlist 2,2,$(RESOLVED))

# suppress "Entering/Leaving directory" messages from make
MAKEFLAGS += --no-print-directory

.PHONY: diff diff-pdf diff-images diff-ext clean help add-tag build build-safe watch
.PHONY: validate validate-git validate-latex validate-tags

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo ""
	@echo "== 基本機能 =="
	@echo "  make build      - LaTeX文書をビルド ($(DEFAULT_TARGET))"
	@echo "  make build-safe - バリデーション付きビルド"
	@echo "  make watch      - ファイル変更を監視して自動ビルド"
	@echo "  make clean      - 出力ファイルをクリーンアップ"
	@echo ""
	@echo "== 差分生成 =="
	@echo "  make diff        - 指定バージョン間の差分一覧 (文書差分のPDF, 画像差分, 拡張子ごとの差分) を作成"
	@echo "  make diff-pdf    - 指定バージョン間の文書差分を視覚化したPDFのみを生成"
	@echo "  make diff-images - 指定バージョン間で変更された画像を出力"
	@echo "  make diff-ext    - 指定バージョン間の拡張子ごとの差分を生成"
	@echo ""
	@echo "== バリデーション =="
	@echo "  make validate           - 全体の状態確認（Git, LaTeX, タグ）"
	@echo "  make validate-git       - Git状態確認"
	@echo "  make validate-latex     - LaTeXファイル確認"
	@echo "  make validate-tags      - タグ重複確認"
	@echo ""
	@echo "== その他 =="
	@echo "  make add-tag    - 対話式でタグを作成"
	@echo "  make help       - このヘルプを表示"
	@echo ""
	@echo "== ドキュメント =="
	@echo "  docs/Configuration_Examples.md - 設定例とベストプラクティス"
	@echo "  scripts/README.md              - スクリプト詳細仕様"
	@echo ""
	@echo "差分PDF生成の使用例:"
	@echo "  make diff-pdf BASE=v1.0.0 CHANGED=test"
	@echo "  make diff-pdf BASE=HEAD~1 CHANGED=HEAD"
	@echo ""
	@echo "設定ファイル (latex.config) の例:"
	@echo "  IMAGE_EXTENSIONS=png jpg pdf eps"

# LaTeX文書ビルド
build:
	@echo "LaTeX文書をビルド中..."
	@echo "ターゲット: $(TARGET)"
	@./scripts/build/build.sh build "$(TARGET)"
	@echo "ビルド完了"

# バリデーション付きビルド
build-safe:
	@echo "=== 安全ビルド（バリデーション付き） ==="
	@echo "ターゲット: $(TARGET)"
	@$(MAKE) validate TARGET="$(TARGET)"
	@echo ""
	@$(MAKE) build TARGET="$(TARGET)"
	@echo "安全ビルド完了"

# ファイル変更監視ビルド
watch:
	@echo "ファイル変更監視モード開始..."
	@echo "ターゲット: $(TARGET)"
	@echo "Ctrl+C で停止"
	@./scripts/build/build.sh watch "$(TARGET)"

# 差分生成
diff:
	@echo "差分生成 (all): TARGET_BASE=$(TARGET_BASE) TARGET_CHANGED=$(TARGET_CHANGED) | 差分: $(RESOLVED_BASE) -> $(RESOLVED_CHANGED) | OUT=$(OUT)"
	@MODE=all bash ./scripts/diff/main.sh "$(TARGET_BASE)" "$(TARGET_CHANGED)" "$(RESOLVED_BASE)" "$(RESOLVED_CHANGED)" "$(OUT)"

# 差分PDF生成
diff-pdf:
	@echo "差分PDF生成: TARGET_BASE=$(TARGET_BASE) TARGET_CHANGED=$(TARGET_CHANGED) | 差分: $(RESOLVED_BASE) -> $(RESOLVED_CHANGED) | OUT=$(OUT)"
	@MODE=pdf bash ./scripts/diff/main.sh "$(TARGET_BASE)" "$(TARGET_CHANGED)" "$(RESOLVED_BASE)" "$(RESOLVED_CHANGED)" "$(OUT)"

# 変更済み画像の出力
diff-images:
	@echo "変更済み画像出力: TARGET_BASE=$(TARGET_BASE) TARGET_CHANGED=$(TARGET_CHANGED) | 差分: $(RESOLVED_BASE) -> $(RESOLVED_CHANGED) | OUT=$(OUT)"
	@MODE=images bash ./scripts/diff/main.sh "$(TARGET_BASE)" "$(TARGET_CHANGED)" "$(RESOLVED_BASE)" "$(RESOLVED_CHANGED)" "$(OUT)"

# 拡張子差分生成
diff-ext:
	@echo "拡張子差分生成: TARGET_BASE=$(TARGET_BASE) TARGET_CHANGED=$(TARGET_CHANGED) | 差分: $(RESOLVED_BASE) -> $(RESOLVED_CHANGED) | OUT=$(OUT)"
	@MODE=ext bash ./scripts/diff/main.sh "$(TARGET_BASE)" "$(TARGET_CHANGED)" "$(RESOLVED_BASE)" "$(RESOLVED_CHANGED)" "$(OUT)"


# 対話式タグ作成
add-tag:
	@echo "現在のタグ:"
	@git tag
	@echo ""
	@read -p "新しいタグ名 (例: v2.0): " tag_name; \
	read -p "タグメッセージ (例: Second version for review): " tag_message; \
	$(MAKE) --no-print-directory validate-tags TAG="$$tag_name" >/dev/null || { echo "エラー: タグ '$$tag_name' は既に存在するか検証に失敗しました"; exit 1; }; \
	git tag -a "$$tag_name" -m "$$tag_message"; \
	echo "タグ '$$tag_name' を作成しました"

# クリーンアップ
clean:
	@echo "出力ファイルをクリーンアップ中..."
	@echo "ターゲット: $(TARGET)"
	@./scripts/build/build.sh clean "$(TARGET)"
	@rm -rf diff_output
	@echo "クリーンアップ完了"

# =============================================================================
# バリデーション機能
# =============================================================================

# 全体バリデーション
validate:
	@echo "=== 全体バリデーション ==="
	@echo "プロジェクトの状態を確認中..."
	@echo ""
	@$(MAKE) --no-print-directory validate-git
	@echo ""
	@$(MAKE) --no-print-directory validate-latex TARGET="$(TARGET)"
	@echo ""
	@$(MAKE) --no-print-directory validate-tags || true
	@echo ""
	@echo "=== バリデーション完了 ==="

# Git状態確認
validate-git:
	@./scripts/validate/validate_git.sh

# LaTeX状態確認
validate-latex:
	@# Invoke the validation script; pass TARGET if provided
	@./scripts/validate/validate_latex.sh "$(TARGET)"

# タグ重複確認
validate-tags:
	@./scripts/validate/validate_tags.sh "$(TAG)"
