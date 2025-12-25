#!/bin/bash
set -e
# 設定
SIDECAR_DIR="trials"
ID_FILE=".current_exp"

# ID生成 (日付+ランダム)
generate_id() {
    echo "EXP-$(date +%Y%m%d-%H%M%S-%N)-$(awk -v seed=$RANDOM 'BEGIN {srand(seed); for(i=0;i<4;i++) printf "%x", int(rand()*16)}')"
}

COMMAND=$1
ARG1=$2

ensure_sidecar() {
    if [ ! -d "$SIDECAR_DIR" ]; then
        mkdir -p "$SIDECAR_DIR"
    fi
}

if [ "$COMMAND" == "start" ]; then
    # 実験開始: ID発行、ブランチ作成、Markdown作成
    [ -n "$(git status --porcelain)" ] && echo "❌ リポジトリが変更されています。" && exit 1
    EXP_ID=$(generate_id)
    git checkout -b "exp/$EXP_ID"
    echo "$EXP_ID" > "$ID_FILE"
    git add "$ID_FILE" && git commit -m "Start $EXP_ID"

    ensure_sidecar
    mkdir -p "$SIDECAR_DIR/$EXP_ID"
    TICKET="$SIDECAR_DIR/$EXP_ID/ticket.md"
    echo "# Experiment: $EXP_ID" > "$TICKET"
    echo "**タイトル:** $ARG1" >> "$TICKET"
    echo "**日付:** $(date)" >> "$TICKET"

    cd "$SIDECAR_DIR" && git add . && git commit -m "Start $EXP_ID"
    echo "🚀 実験を開始しました: $EXP_ID"

elif [ "$COMMAND" == "record" ]; then
    # 手動記録
    [ ! -f "$ID_FILE" ] && echo "❌ 実行中の実験がありません。" && exit 1
    EXP_ID=$(cat "$ID_FILE")
    TICKET="$SIDECAR_DIR/$EXP_ID/ticket.md"
    HASH=$(git rev-parse --short HEAD)

    cat <<EOF >> "$TICKET"
### 📝 Record
- **Commit:** \`$HASH\`
- **Note:** $ARG1
EOF
    cd "$SIDECAR_DIR" && git add . && git commit -m "Log $EXP_ID"
    echo "✅ 記録しました。"

elif [ "$COMMAND" == "close" ]; then
    # 終了処理: マージまたは破棄
    RESULT=$ARG1
    [ ! -f "$ID_FILE" ] && echo "❌ 実行中の実験がありません。" && exit 1
    EXP_ID=$(cat "$ID_FILE")
    BRANCH=$(git symbolic-ref --short HEAD)

    TICKET="$SIDECAR_DIR/$EXP_ID/ticket.md"
    echo -e "\n## 結論\n**結果:** $RESULT" >> "$TICKET"
    cd "$SIDECAR_DIR" && git add . && git commit -m "Close $EXP_ID ($RESULT)"
    cd ..

    git checkout main
    if [ "$RESULT" == "success" ]; then
        git merge --no-ff "$BRANCH" -m "Merge $EXP_ID"
        git branch -d "$BRANCH"
        echo "✅ マージ完了しました。"
    elif [ "$RESULT" == "fail" ] || [ "$RESULT" == "discard" ]; then
        git branch -D "$BRANCH"
        echo "✅ コードを破棄しました（チケットは保存されました）。"
    else
        echo "❌ 結果ステータスが不明です: '$RESULT'"
        echo "   - マージする場合: make close RESULT=success (または空)"
        echo "   - 破棄する場合:   make close RESULT=fail (または discard)"
        echo "⚠️ ブランチ '$BRANCH' はまだ削除されていません。確認してください。"
        exit 1
    fi

else
    echo "❌ 不明なコマンド: $COMMAND"
    exit 1
fi
