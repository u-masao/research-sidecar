# ワークフロー移植ガイド (Porting Guide)

このガイドでは、この**Research Workflow Automation**（Sidecar Workflow）を他の既存または新規プロジェクトへ移植する方法について解説します。

## 概要

このワークフローは、実験の追跡、再現性確保、ナレッジ蓄積を支援するために設計されています。主に以下のコンポーネントから構成されています。

1.  **Scripts (`scripts/`)**: 実験のライフサイクル（開始、実行、保存）を管理するスクリプト群。
2.  **Sidecar (`trials/`)**: ソースコードとは独立したブランチ（`experiments`）で管理される実験ノート・結果。
3.  **Agents (`AGENTS.md`)**: AIエージェントに自律的に実験を行わせるための指示書。

## 前提条件

移植先の環境で以下がインストールされている・設定されている必要があります。

*   **Git**: バージョン管理システム。
*   **uv**: Pythonパッケージマネージャー（推奨）。
*   **DVC**: データバージョン管理（`dvc.yaml` などを使用する前提の場合）。
*   **make**: コマンド実行用。

## 移植手順

### 自動セットアップ (推奨)

手動での移植が面倒な場合は、以下のコマンド（One-liner）を実行することで、必要なファイルのダウンロードと設定を自動で行えます。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/u-masao/research-sidecar/main/scripts/install.sh)"
```

インストール後、**`scripts/run_core.sh` のカスタマイズ**（後述の手順5相当）のみ手動で行ってください。

---

以下は、手動で移植する場合の手順です。

### 1. スクリプトのコピー

`scripts/` ディレクトリ内のシェルスクリプトを、移植先のプロジェクトの `scripts/` ディレクトリにコピーします。

*   `scripts/cycle.sh`
*   `scripts/run_core.sh`
*   `scripts/run_experiment.sh`
*   `scripts/rs.mk`
*   `scripts/test_workflow.sh`（オプション: 動作確認用）

```bash
mkdir -p scripts
cp /path/to/source/scripts/*.sh ./scripts/
chmod +x scripts/*.sh
```

### 2. .gitignore の設定

Gitの管理対象外ファイルを設定します。特に `trials/` ディレクトリと実験IDの一時ファイル `.current_exp` は必ず除外してください。

`.gitignore` に以下を追記します:

```gitignore
# Research Workflow
.current_exp
trials/
```

### 3. Makefile のマージ

最も簡単な方法は、提供されている `scripts/rs.mk` を利用することです。

1. `scripts/rs.mk` をコピーします。
2. 既存の `Makefile` の先頭に `include scripts/rs.mk` を追記します。もし `Makefile` がない場合は新規作成してください。

```makefile
include scripts/rs.mk

.PHONY: clean help

help:
	@echo "Main Makefile Help:"
	@$(MAKE) help-rs
```

### 4. AGENTS.md の配置

AIエージェント（CurserやWindsurfなど）を使用する場合は、プロジェクトのルートに `AGENTS.md` を配置します。これにより、エージェントがワークフローのルールや実験の進め方を理解できるようになります。

### 5. run_core.sh のカスタマイズ

`scripts/run_core.sh` は、実際の実験コマンドや成果物のパスを定義する場所です。プロジェクトに合わせて以下の箇所を修正してください。

1.  **実行コマンド**: `uv run dvc repro` の部分を、そのプロジェクトの実行コマンド（例: `python train.py`）に変更します。
2.  **成果物のコピー**: `cp -r reports/metrics.json ...` の部分を、保存したいファイル（重み、ログ、画像など）に合わせて変更します。

```bash
# 例: 実行コマンドの変更
# uv run dvc repro
python src/train.py

# 例: 成果物パスの変更
# cp -r reports/metrics.json "$SIDECAR_DIR/$EXPERIMENT_ID/reports/"
cp results/scores.csv "$SIDECAR_DIR/$EXPERIMENT_ID/reports/"
```

## 動作確認

移植が完了したら、以下のコマンドで動作確認を行います。

1.  セットアップとSidecarの初期化:
    ```bash
    make rs-setup
    ```

2.  テストスクリプトの実行（`test_workflow.sh` をコピーした場合）:
    ```bash
    ./scripts/test_workflow.sh
    ```
    または手動で:
    ```bash
    make rs-start MSG="Test Experiment"
    make rs-run MSG="Initial Run"
    make rs-close RESULT="success"
    ```

## 運用レシピ (Best Practices)

### 繰り返し実験を行う場合 (Iterative Experiments)
同じ実験IDの中でパラメータを変えて試行錯誤する場合は、新しい実験を開始(`make rs-start`)するのではなく、`spec.md` を更新して `make rs-run` を繰り返してください。

1. **`spec.md` を更新**: 「パラメータを変更して再試行」などのメモを追記。
2. **コード修正 & 実行**: `make rs-run MSG="Change param alpha"`。
3. **結果確認**: Sidecarに履歴が追記されます。

### 実験をキャンセルする場合
`make rs-start` 直後に「やっぱりやめた」となった場合は、失敗としてクローズすればブランチごと削除され、きれいになります。

```bash
make rs-close RESULT="discard"
```
これで実験用ブランチ (`exp/EXP-xxxx`) は削除され、Sidecar内のチケットもクローズされます（チケット自体はログとして残ります）。
