# --- Research Sidecar (rs) Workflow ---
.PHONY: rs-setup rs-start rs-run rs-close rs-push rs-pull help-rs

help-rs:
	@echo "使用方法 (Research Sidecar):"
	@echo "  make rs-setup   - 環境構築 (uv install, Research Sidecar setup)"
	@echo "  make rs-start   - 実験開始 (./scripts/cycle.sh start)"
	@echo "                  * 必須: MSG=\"実験タイトル\""
	@echo "  make rs-run     - 実験実行 & 記録 (./scripts/run_experiment.sh)"
	@echo "                  * 任意: MSG=\"コミットメッセージ\""
	@echo "  make rs-close   - 実験終了 (./scripts/cycle.sh close)"
	@echo "                  * 必須: RESULT={success|fail|discard}"
	@echo "  make rs-push    - 全ブッシュ (Code + Research Sidecar)"
	@echo "  make rs-pull    - 全プル (Code + Research Sidecar)"
	@echo ""
	@echo "例:"
	@echo "  make rs-start MSG=\"Base Model Evaluation\""
	@echo "  make rs-run MSG=\"Changed learning rate\""
	@echo "  make rs-close RESULT=success"
	@echo ""

rs-setup:
	@echo "🔧 Research Sidecar 環境セットアップ中..."
	@which uv > /dev/null || (echo "❌ uv が見つかりません。インストールしてください: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
	uv sync
	@chmod +x scripts/cycle.sh scripts/run_experiment.sh
	@# Research Sidecar Setup
	@if [ ! -d "trials" ]; then \
		echo "Initializing Research Sidecar (trials)..."; \
		if git rev-parse --verify experiments >/dev/null 2>&1; then \
			git worktree add trials experiments; \
		else \
			git checkout --orphan experiments; \
			git rm -rf .; \
			git commit --allow-empty -m "Initial commit for Research Sidecar Experiments"; \
			git checkout -; \
			git worktree add trials experiments; \
		fi \
	fi
	@echo "✅ Research Sidecar セットアップ完了"

rs-start:
	@if [ -z "$(MSG)" ]; then \
		echo "❌ エラー: MSG (実験タイトル) が指定されていません。"; \
		echo "👉 例: make rs-start MSG=\"Base Model Evaluation\""; \
		exit 1; \
	fi
	./scripts/cycle.sh start "$(MSG)"

rs-run:
	./scripts/run_experiment.sh "$(MSG)"

rs-close:
	@if [ -z "$(RESULT)" ]; then \
		echo "❌ エラー: RESULT (結果ステータス) が指定されていません。"; \
		echo "👉 例: make rs-close RESULT=success"; \
		exit 1; \
	fi
	./scripts/cycle.sh close "$(RESULT)"

rs-push:
	git push origin main
	git push origin experiments
	uv run dvc push

rs-pull:
	git pull origin main
	(cd trials && git pull origin experiments)
	uv run dvc pull
