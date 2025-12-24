#!/bin/bash
set -e

# 環境変数の確認
if [ -z "$EXPERIMENT_ID" ] || [ -z "$SIDECAR_DIR" ]; then
    echo "❌ エラー: EXPERIMENT_ID または SIDECAR_DIR が設定されていません。"
    exit 1
fi

MSG=$1

# 1. 実験実行 (DVC)
echo "▶️ DVC実験を実行中..."
uv run dvc repro

# 2. Lockファイルのコミット
# 変更があればコミットする
git add dvc.lock dvc.yaml
if ! git diff --cached --quiet; then
    git commit -m "Run $EXPERIMENT_ID: $MSG"
fi

# 3. 成果物のSidecarへのコピー
echo "📦 成果物をSidecarにアーカイブ中..."
mkdir -p "$SIDECAR_DIR/$EXPERIMENT_ID/reports"
cp -r reports/metrics.json "$SIDECAR_DIR/$EXPERIMENT_ID/reports/"
