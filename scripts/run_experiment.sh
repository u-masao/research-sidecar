#!/bin/bash
set -e
export SIDECAR_DIR="trials"
ID_FILE=".current_exp"

# 0. 変更チェック
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ リポジトリに変更があります。実験を実行する前にコミットしてください。"
    exit 1
fi

# 1. IDの注入 (Dependency Injection)
if [ -f "$ID_FILE" ]; then
    export EXPERIMENT_ID=$(cat "$ID_FILE")
else
    echo "❌ 実行中の実験が見つかりません。先に 'make start' を実行してください。"
    exit 1
fi

# 2. Sidecar自動修復 (Auto Setup)
if [ ! -f "$SIDECAR_DIR/.git" ]; then
    echo "🔧 Sidecarを初期化中..."
    # ブランチが存在するか確認
    if git rev-parse --verify experiments >/dev/null 2>&1; then
        git worktree add "$SIDECAR_DIR" experiments
    else
        # orphan branch作成
        git checkout --orphan experiments
        git rm -rf .
        git commit --allow-empty -m "Initial commit for Sidecar Experiments"
        git checkout -
        git worktree add "$SIDECAR_DIR" experiments
    fi
fi

# 3. コアロジックの委譲
# 実験の中身（実行・コミット・退避）は別スクリプトに切り出し
./scripts/run_core.sh "$1"

# 4. アンカー記録
HASH=$(git rev-parse --short HEAD)
TICKET="$SIDECAR_DIR/$EXPERIMENT_ID/ticket.md"
[ -f "$TICKET" ] || echo "# $EXPERIMENT_ID" > "$TICKET"

echo "- **Run:** \`$HASH\` (Msg: $1)" >> "$TICKET"
cd "$SIDECAR_DIR" && git add . && git commit -m "Run record $EXPERIMENT_ID"
