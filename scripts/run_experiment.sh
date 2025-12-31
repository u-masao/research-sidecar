#!/bin/bash
set -e
export SIDECAR_DIR="trials"
ID_FILE=".current_exp"

# ヘルプ表示関数
usage() {
    echo "使用方法: $0 [message]"
    echo ""
    echo "説明:"
    echo "  現在進行中の実験を実行します。"
    echo "  内部で DVC (dvc repro) を呼び出し、結果を Sidecar ディレクトリに保存します。"
    echo ""
    echo "引数:"
    echo "  message: 実行時のコミットメッセージ（任意）"
    echo ""
    echo "例:"
    echo "  $0 \"Adjusted hyperparameters\""
    exit 1
}

# ヘルプチェック
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
fi

# 0. 変更チェック
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ エラー: リポジトリに変更があります。実験を実行する前にコミットしてください。"
    echo "   (git add . && git commit -m '...')"
    exit 1
fi

# 1. IDの注入 (Dependency Injection)
if [ -f "$ID_FILE" ]; then
    export EXPERIMENT_ID=$(cat "$ID_FILE")
else
    echo "❌ エラー: 実行中の実験が見つかりません。先に 'make rs-start' を実行してください。"
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
echo "✅ 実験 $EXPERIMENT_ID の実行記録を保存しました。"
