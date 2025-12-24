# リポジトリ利用ガイド (Research Workflow)

このリポジトリは、実験の追跡と文書化を効率化するために設計された「Sidecar Workflow」を採用しています。
実験用コードと結果ログを分離しつつ、連携させる仕組みが特徴です。

## ワークフローの概要

1.  **Setup**: 環境構築とSidecar（`trials`ディレクトリ）の準備
2.  **Start**: 新しい実験サイクルの開始（仕様書 `spec.md` の作成）
3.  **Run**: 実験の実行と記録
4.  **Close**: 実験サイクルの終了と考察（`reflection.md`）
5.  **Push**: コードと実験記録の同期・保存

## ディレクトリ構造

- `trials/`: 実験記録を保持するディレクトリ（Git Worktree: `experiments` ブランチ）
  - 各実験ごとにディレクトリが作成されます（例: `trials/2024-01-01_10-00-00_feat_xxx/`）。
- `scripts/`: ワークフロー制御用スクリプト

## コマンド一覧 (`Makefile`)

| コマンド | 説明 | 詳細 |
| --- | --- | --- |
| `make sidecar-setup` | **環境構築** | `uv sync` で依存関係をインストールし、`trials` ディレクトリ（Sidecar）をセットアップします。 |
| `make sidecar-start` | **実験開始** | 新しい実験IDを発行し、ディレクトリと `spec.md` を作成します。<br>`make sidecar-start MSG="実験タイトル"` のようにメッセージを指定できます。 |
| `make sidecar-run` | **実験実行** | `scripts/run_experiment.sh` を実行します。`spec.md` が存在しないと実行できません。 |
| `make sidecar-close` | **実験終了** | 現在の実験サイクルを閉じ、結果をコミットします。<br>`make sidecar-close RESULT="結果サマリ"` と指定可能です。 |
| `make sidecar-push` | **同期** | メインブランチと `experiments` ブランチ（Sidecar）、およびDVC管理データをPushします。 |
| `make sidecar-pull` | **同期** | メインブランチと `experiments` ブランチ（Sidecar）、およびDVC管理データをPullします。 |

## エージェントの役割 (`AGENTS.md`より)

あなたがAIエージェントを使用する場合、以下の役割を期待されています：
- **仕様書ファースト**: コードを書く前に `spec.md` の記述を支援する。
- **振り返り**: 実験完了後、`metrics.json` を確認し、ユーザーに考察を促して `reflection.md` を更新する。
