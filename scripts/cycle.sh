#!/bin/bash
set -e

# 設定
SIDECAR_DIR="trials"
ID_FILE=".current_exp"

# ヘルプ表示関数
usage() {
    EXIT_CODE=$1
    echo "使用方法: $0 [command] [args]"
    echo ""
    echo "コマンド:"
    echo "  start \"実験タイトル\"   新しい実験を開始します（ID発行、ブランチ作成）"
    echo "  record \"メモ内容\"      現在の実験にメモを記録します"
    echo "  close [result]         実験を終了します"
    echo ""
    echo "引数:"
    echo "  result: 実験の結果ステータス (success, fail, discard)"
    echo ""
    echo "例:"
    echo "  $0 start \"My New Experiment\""
    echo "  $0 record \"Changed learning rate to 0.01\""
    echo "  $0 close success"
    exit $EXIT_CODE
}

# ID生成 (日付+ランダム)
generate_id() {
    # Format: EXP-YYYYMMDD-HHMMSS-NNN-XXXX
    echo "EXP-$(date +%Y%m%d-%H%M%S-%3N)-$(awk -v seed=$RANDOM 'BEGIN {srand(seed); for(i=0;i<4;i++) printf "%x", int(rand()*16)}')"
}

# 引数チェック
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage 0
fi

if [ -z "$1" ]; then
    usage 1
fi

COMMAND=$1
ARG1=$2

ensure_sidecar() {
    if [ ! -d "$SIDECAR_DIR" ]; then
        mkdir -p "$SIDECAR_DIR"
    fi
}

if [ "$COMMAND" == "start" ]; then
    # バリデーション
    if [ -z "$ARG1" ]; then
        echo "❌ エラー: 実験タイトルが必要です。"
        usage 1
    fi
    if [ -f "$ID_FILE" ]; then
        EXISTING_ID=$(cat "$ID_FILE")
        echo "❌ エラー: 実験 $EXISTING_ID が進行中です。先に終了してください (make rs-close)。"
        exit 1
    fi
    if [ -n "$(git status --porcelain)" ]; then
        echo "❌ エラー: リポジトリに変更があります。コミットするかstashしてください。"
        exit 1
    fi

    # 実験開始: ID発行、ブランチ作成、Markdown作成
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
    # バリデーション
    if [ -z "$ARG1" ]; then
        echo "❌ エラー: 記録するメモ内容が必要です。"
        usage 1
    fi
    if [ ! -f "$ID_FILE" ]; then
        echo "❌ エラー: 実行中の実験がありません。"
        exit 1
    fi

    # 手動記録
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
    RESULT=$ARG1

    # バリデーション
    if [ ! -f "$ID_FILE" ]; then
        echo "❌ エラー: 実行中の実験がありません。"
        exit 1
    fi

    # RESULTの事前チェック
    if [ -z "$RESULT" ]; then
        echo "❌ エラー: 結果ステータスが必要です。"
        usage 1
    fi

    if [ "$RESULT" != "success" ] && [ "$RESULT" != "fail" ] && [ "$RESULT" != "discard" ]; then
        echo "❌ エラー: 不明な結果ステータスです: '$RESULT'"
        echo "   利用可能な値: success, fail, discard"
        exit 1
    fi

    # 終了処理: マージまたは破棄
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
        echo "✅ 実験 $EXP_ID を正常に完了・マージしました。"
    elif [ "$RESULT" == "fail" ] || [ "$RESULT" == "discard" ]; then
        git branch -D "$BRANCH"
        echo "✅ 実験 $EXP_ID のコードを破棄しました（記録は $SIDECAR_DIR に保存されました）。"
    fi

    # IDファイルの削除 (ここで確実に消す)
    rm -f "$ID_FILE"

else
    echo "❌ 不明なコマンド: $COMMAND"
    usage 1
fi
