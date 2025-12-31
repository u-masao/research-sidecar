# デプロイ手順 (Deployment Guide)

このプロジェクト (`research-workflow-automation-trial`) の成果物を、配布用リポジトリ (`research-sidecar`) へデプロイ（反映）する手順です。

## 前提

*   **作業リポジトリ**: `research-workflow-automation-trial` (本リポジトリ)
*   **配布先リポジトリ**: `research-sidecar` (Remote名: `research-sidecar`)
*   **デプロイ用ブランチ**: `rs-release` (このブランチで作業し、配布先の `main` にPushします)

## 手順

### 1. 準備

`rs-release` ブランチに切り替え、配布先 (upstream) の最新状態を取り込みます。

```bash
# デプロイ用ブランチへ切り替え
git checkout rs-release

# 配布先の最新 state を取得してマージ (コンフリクト防止)
git fetch research-sidecar
git merge research-sidecar/main
```

### 2. コンテンツの更新

`main` ブランチから、配布に必要なファイル群のみをチェックアウトして上書きします。
※ プロジェクト固有の `src/` や `dvc.yaml` などは含めないように注意してください。

```bash
# デプロイ用ブランチへ切り替え
git switch rs-release

# 必要なディレクトリ/ファイルを main から取得
git checkout main -- AGENTS.md scripts docs

# 差分を確認
git status
git diff --stat
```

### 3. コミット

変更内容をコミットします。機能単位（ドキュメント、スクリプト等）で分割することを推奨します。

```bash
# ドキュメントの更新
git add docs AGENTS.md
git commit -m "docs: update documentation"

# スクリプトの更新
git add scripts
git commit -m "feat(scripts): update workflow scripts"
```

### 4. プッシュ (デプロイ)

`rs-release` ブランチの内容を、`research-sidecar` の `main` ブランチとしてプッシュします。

```bash
git push research-sidecar rs-release:main
```

## 注意事項

*   Push が reject された場合は、手順1のマージが不足している可能性があります。再度 `git merge research-sidecar/main` を行ってください。
*   `research-sidecar` リポジトリは「汎用的なワークフロー」の配布元です。特定の実験データやプロジェクト固有のコードを含めないよう、`.gitignore` やチェックアウト対象に注意してください。
