# LaTeX論文差分計算用Makefile
# DVC統合バージョン

# 設定ファイルの読み込み
ifneq (,$(wildcard latex.config))
    include latex.config
    export
endif

# デフォルト設定
MAIN_TEX ?= src/main.tex
IMAGE_EXTENSIONS ?= png jpg jpeg pdf eps svg
DVC_MANAGED_DIRS ?= figures
DVC_REMOTE_NAME ?= storage
DVC_REMOTE_URL ?=
LATEX_ENGINE ?= lualatex
BIBTEX_ENGINE ?= bibtex
ENABLE_LATEXINDENT ?= true

# Make-level TARGET default (can be overridden on command line)
TARGET ?= $(MAIN_TEX)

# suppress "Entering/Leaving directory" messages from make
MAKEFLAGS += --no-print-directory

.PHONY: diff diff-pdf clean help test-tag build build-safe watch
.PHONY: dvc-init dvc-status dvc-check-connection dvc-add-images _check-dvc-initialized
.PHONY: validate validate-git validate-latex validate-dvc validate-tags
.PHONY: show-image-status dvc-exclude-image dvc-include-image
.PHONY: dvc-restore-file dvc-restore-all dvc-remove
.PHONY: dvc-remote-add dvc-remote-list dvc-remote-test dvc-push dvc-pull dvc-fetch

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo ""
	@echo "== 基本機能 =="
	@echo "  make build      - LaTeX文書をビルド ($(MAIN_TEX))"
	@echo "  make build-safe - バリデーション付きビルド"
	@echo "  make watch      - ファイル変更を監視して自動ビルド"
	@echo "  make clean      - 出力ファイルをクリーンアップ"
	@echo ""
	@echo "== 差分生成 =="
	@echo "  make diff       - 直前の変更を表示"
	@echo "  make diff-pdf   - 指定されたバージョン間の視覚的差分PDFを生成"
	@echo ""
	@echo "== DVC機能 =="
	@echo "  make dvc-init           - DVCを初期化し既存画像を管理対象に追加"
	@echo "  make dvc-status         - DVC状態を確認"
	@echo "  make dvc-check-connection - DVCリモート接続を確認"
	@echo "  make dvc-add-images     - 新規・変更画像をDVC管理に追加"
	@echo "  make show-image-status  - 画像ファイルの管理状況を表示"
	@echo "  make dvc-exclude-image FILE=path - 画像をDVC除外リストに追加"
	@echo "  make dvc-include-image FILE=path - 画像をDVC除外リストから削除"
	@echo "  make dvc-restore-file FILE=path  - 指定ファイルをGit管理に復元"
	@echo "  make dvc-restore-all    - 全DVC管理ファイルをGit管理に復元"
	@echo "  make dvc-remove         - DVC設定を完全削除"
	@echo ""
	@echo "== DVCリモート管理 =="
	@echo "  make dvc-remote-add NAME=name URL=url - リモート追加"
	@echo "  make dvc-remote-list    - リモート一覧表示"
	@echo "  make dvc-remote-test    - リモート接続テスト"
	@echo "  make dvc-push           - データをリモートにプッシュ"
	@echo "  make dvc-pull           - データをリモートからプル"
	@echo "  make dvc-fetch          - リモートデータの確認"
	@echo ""
	@echo "== バリデーション =="
	@echo "  make validate           - 全体の状態確認（Git, LaTeX, DVC）"
	@echo "  make validate-git       - Git状態確認"
	@echo "  make validate-latex     - LaTeXファイル確認"
	@echo "  make validate-dvc       - DVC状態確認"
	@echo "  make validate-tags      - タグ重複確認"
	@echo ""
	@echo "== その他 =="
	@echo "  make test-tag   - テスト用のタグを作成"
	@echo "  make help       - このヘルプを表示"
	@echo ""
	@echo "== ドキュメント =="
	@echo "  docs/DVC_Workflow.md           - DVC統合ワークフローの詳細"
	@echo "  docs/Configuration_Examples.md - 設定例とベストプラクティス"
	@echo "  scripts/README.md              - スクリプト詳細仕様"
	@echo ""
	@echo "差分PDF生成の使用例:"
	@echo "  make diff-pdf BASE=v1.0.0 CHANGED=test"
	@echo "  make diff-pdf BASE=HEAD~1 CHANGED=HEAD"
	@echo ""
	@echo "DVC初期化の使用例:"
	@echo "  make dvc-init"
	@echo "  make dvc-init DVC_REMOTE_URL=s3://your-bucket/latex-figures"
	@echo ""
	@echo "設定ファイル (latex.config) の例:"
	@echo "  IMAGE_EXTENSIONS=png jpg pdf eps"
	@echo "  DVC_MANAGED_DIRS=figures images data"
	@echo "  DVC_REMOTE_URL=ssh://user@server/path/to/storage"

# LaTeX文書ビルド
build:
	@echo "LaTeX文書をビルド中..."
	@./scripts/build/build.sh build "$(TARGET)"
	@echo "ビルド完了"

# バリデーション付きビルド
build-safe:
	@echo "=== 安全ビルド（バリデーション付き） ==="
	@$(MAKE) validate TARGET="$(TARGET)"
	@echo ""
	@$(MAKE) build TARGET="$(TARGET)"
	@echo "安全ビルド完了"

# ファイル変更監視ビルド
watch:
	@echo "ファイル変更監視モード開始..."
	@echo "Ctrl+C で停止"
	@./scripts/build/build.sh watch "$(TARGET)"

# Git差分表示
diff:
	@if [ -n "$(BASE)" ] && [ -n "$(CHANGED)" ]; then \
		echo "Git差分表示中: $(BASE) → $(CHANGED)"; \
		git diff $(BASE)..$(CHANGED); \
	else \
		echo "デフォルト差分表示中 (HEAD~1..HEAD)..."; \
		echo "特定のタグ/コミット間の差分を表示するには:"; \
		echo "  make diff BASE=v1.0.0 CHANGED=v2.0.0"; \
		git diff HEAD~1..HEAD; \
	fi

# 視覚的差分PDF生成
diff-pdf:
	@if [ -z "$(BASE)" ] || [ -z "$(CHANGED)" ]; then \
		echo "エラー: BASE と CHANGED パラメータが必要です"; \
		echo "使用例: make diff-pdf BASE=v1.0.0 CHANGED=test"; \
		exit 1; \
	fi
	@echo "差分PDF生成中: $(BASE) → $(CHANGED)"
	@./scripts/generate_diff.sh $(MAIN_TEX) $(BASE) $(CHANGED)

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
	@./scripts/build/build.sh clean "$(TARGET)"
	@rm -rf diff_output
	@echo "クリーンアップ完了"

# =============================================================================
# DVC関連機能
# =============================================================================

# DVC初期化確認
_check-dvc-initialized:
	@if [ ! -d ".dvc" ]; then \
		echo "エラー: DVCが初期化されていません"; \
		echo "まず 'make dvc-init' を実行してください"; \
		exit 1; \
	fi

# DVC初期化とセットアップ
dvc-init:
	@echo "=== DVC初期化とセットアップ ==="
	@echo "設定:"
	@echo "  管理対象ディレクトリ: $(DVC_MANAGED_DIRS)"
	@echo "  画像ファイル拡張子: $(IMAGE_EXTENSIONS)"
	@echo "  リモート名: $(DVC_REMOTE_NAME)"
	@if [ -n "$(DVC_REMOTE_URL)" ]; then \
		echo "  リモートURL: $(DVC_REMOTE_URL)"; \
	else \
		echo "  リモートURL: 未設定（後で手動設定が必要）"; \
	fi
	@echo
	@read -p "続行しますか? [y/N]: " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "キャンセルしました"; \
		exit 1; \
	fi
	@./scripts/dvc_init.sh "$(DVC_REMOTE_NAME)" "$(DVC_REMOTE_URL)" "$(DVC_MANAGED_DIRS)" "$(IMAGE_EXTENSIONS)"
	@echo "=== DVC初期化完了 ==="
	@echo "既存画像がDVC管理下に追加されました"

# DVC状態確認
dvc-status:
	@./scripts/dvc_validator.sh status "$(DVC_MANAGED_DIRS)"

# DVC接続確認
dvc-check-connection:
	@./scripts/dvc_validator.sh check-connection "$(DVC_REMOTE_NAME)"

# DVC画像追加（新規・変更画像の自動検出と追加）
dvc-add-images:
	@echo "=== DVC画像追加 ==="
	@$(MAKE) _check-dvc-initialized
	@echo "新規・変更画像ファイルを検索中..."
	@./scripts/image_manager.sh show-changes "$(DVC_MANAGED_DIRS)" "$(IMAGE_EXTENSIONS)"
	@echo ""
	@echo "⚠ 注意: DVC管理に追加すると画像ファイルはGit管理から除外されます"
	@echo "        リポジトリ公開時はSSHリモートアクセスが必要になります"
	@echo ""
	@read -p "これらの画像をDVC管理に追加しますか? [y/N]: " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "キャンセルしました"; \
		exit 1; \
	fi
	@./scripts/image_manager.sh add-safe "$(DVC_MANAGED_DIRS)" "$(IMAGE_EXTENSIONS)"
	@echo "=== DVC画像追加完了 ==="

# =============================================================================
# 画像管理機能（公開対応）
# =============================================================================

# 画像をDVC除外リストに追加
dvc-exclude-image:
	@if [ -z "$(FILE)" ]; then \
		echo "エラー: FILE パラメータが必要です"; \
		echo "使用例: make dvc-exclude-image FILE=figures/logo.png"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "エラー: ファイル $(FILE) が見つかりません"; \
		exit 1; \
	fi
	@bash -c 'source ./scripts/common.sh && add_to_exclude_list "$(FILE)"'

# 画像をDVC除外リストから削除
dvc-include-image:
	@if [ -z "$(FILE)" ]; then \
		echo "エラー: FILE パラメータが必要です"; \
		echo "使用例: make dvc-include-image FILE=figures/logo.png"; \
		exit 1; \
	fi
	@bash -c 'source ./scripts/common.sh && remove_from_exclude_list "$(FILE)"'

# 画像ファイルの管理状況表示
show-image-status:
	@./scripts/image_manager.sh show-status "$(DVC_MANAGED_DIRS)" "$(IMAGE_EXTENSIONS)"

# DVC復元機能
dvc-restore-file:
	@if [ -z "$(FILE)" ]; then \
		echo "エラー: FILE パラメータが必要です"; \
		echo "使用例: make dvc-restore-file FILE=figures/image.png"; \
		exit 1; \
	fi
	@./scripts/dvc_restore.sh file "$(FILE)"

dvc-restore-all:
	@./scripts/dvc_restore.sh all "$(DVC_MANAGED_DIRS)"

dvc-remove:
	@./scripts/dvc_restore.sh remove

# =============================================================================
# DVCリモート管理機能
# =============================================================================

# リモート追加
dvc-remote-add:
	@if [ -z "$(NAME)" ] || [ -z "$(URL)" ]; then \
		echo "エラー: NAME と URL パラメータが必要です"; \
		echo "使用例: make dvc-remote-add NAME=storage URL=ssh://user@server/path"; \
		exit 1; \
	fi
	@./scripts/dvc_remote.sh add "$(NAME)" "$(URL)"

# リモート一覧
dvc-remote-list:
	@./scripts/dvc_remote.sh list

# リモート接続テスト
dvc-remote-test:
	@./scripts/dvc_remote.sh test "$(REMOTE)"

# データプッシュ
dvc-push:
	@./scripts/dvc_remote.sh push "$(REMOTE)"

# データプル
dvc-pull:
	@./scripts/dvc_remote.sh pull "$(REMOTE)"

# データフェッチ
dvc-fetch:
	@./scripts/dvc_remote.sh fetch "$(REMOTE)"

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
	@$(MAKE) --no-print-directory validate-dvc || true
	@echo ""
	@$(MAKE) --no-print-directory validate-tags || true
	@echo ""
	@echo "=== バリデーション完了 ==="

# Git状態確認
validate-git:
	@./scripts/validator/validate_git.sh

# LaTeX状態確認
validate-latex:
	@# Invoke the validation script; pass TARGET if provided
	@./scripts/validator/validate_latex.sh "$(TARGET)"

# DVC状態確認
validate-dvc:
	@./scripts/dvc_validator.sh validate "$(DVC_MANAGED_DIRS)"

# タグ重複確認
validate-tags:
	@./scripts/validator/validate_tags.sh "$(TAG)"
