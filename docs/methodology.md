# 実験ワークフロー・方法 (Methodology)

本ドキュメントでは、本テンプレートを使用した具体的な実験の進め方（How-To）について解説します。
コマンドは基本的に `Makefile` を通じて実行します。

## 1. セットアップ (Setup)

プロジェクトをクローンした後、最初に一度だけ実行します。

```bash
make sidecar-setup
```

このコマンドは以下を行います：
1.  `uv` を使用してPythonの依存パッケージをインストールします。
2.  `trials/` ディレクトリに Git Worktree (experiments branch) を設定します（Sidecar環境の構築）。

## 2. 実験サイクル (Experiment Cycle)

実験は以下のサイクルで回します。

### Step 1: 実験の開始 (Start)

新しい実験を開始する準備をします。

```bash
make sidecar-start
```
または引数付きで：
```bash
make sidecar-start MSG="improve_attention_mechanism"
```

これにより、スクリプト（`scripts/cycle.sh`）が実行され、以下が行われます：
*   ソースコードの変更がある場合、自動的にコミットされます。
*   `trials/` 以下に新しい実験IDを持つディレクトリ（例: `trials/2024-01-01_10-00-00_feat_xxx/`）が作成されます。
*   そのディレクトリ内にテンプレートから `spec.md` が生成されます。

### Step 2: 仕様の記述 (Specify)

生成された `spec.md` を編集します。AIエディタ（Cursor等）を使用している場合、ここで実験の意図や仮説を記述することで、次のステップの実装をAIに任せやすくなります。

*   **場所:** `trials/{latest_experiment_id}/spec.md`
*   **内容:** 実験の背景、仮説、検証方法、期待される結果など。

### Step 3: 実装 (Implement)

`src/` 内のコードや、実験スクリプトを修正・実装します。

### Step 4: 実行 (Run)

実験を実行します。

```bash
make sidecar-run
```

*   `run_experiment.py` が呼び出され、実験スクリプトが実行されます。
*   現在のソースコードのスナップショットが `trials/{exp_id}/snapshot/` に保存されます。
*   実行ログは `trials/{exp_id}/run.log` に保存されます。
*   結果（Metrics）は `trials/{exp_id}/reports/metrics.json` に出力されることが期待されます。

### Step 5: 振り返り (Reflect)

実験終了後、自動的に（または手動で）振り返りプロセスに入ります。
生成された `metrics.json` やログを元に、AIエージェントと対話し、考察を `reflection.md` に記録します。

### Step 6: 終了と保存 (Close & Push)

実験サイクルを終了し、結果を保存します。

```bash
make sidecar-close
make sidecar-push
```

*   **`make sidecar-close`**: 実験結果（`trials/` 内の変更）をコミットします。
*   **`make sidecar-push`**: メインブランチと実験ブランチ（experiments）の両方をリモートリポジトリにプッシュします。

## 3. その他のコマンド

*   **`make clean`**: 生成されたキャッシュファイルなどを削除します。
*   **`make sync`**: `uv sync` を実行し、依存関係を同期します。
*   **`make new`**: (Legacy) 旧来のフォルダベースの実験作成コマンドです。

## 4. トラブルシューティング

### 実験フォルダが見当たらない
`trials/` ディレクトリを確認してください。Git Worktreeを使用しているため、エディタによってはファイルツリーの更新が必要な場合があります。

### "Dirty state" エラー
実験開始時に未コミットの変更があると警告が出る場合があります。再現性のため、ソースコードの変更はこまめにコミットすることを推奨します。強制的に実行したい場合は `scripts/run_experiment.sh` の引数を確認してください（通常は非推奨です）。
