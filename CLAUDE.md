# k8s-kind-lab ルール

Kind で K8s を学ぶ学習用リポジトリ。`~/Dev/study/CLAUDE.md` の「学習優先」ルールに従う。

## 進め方
- 完成したマニフェストやコードを、いきなり書かない。意図の整理 → ヒント → 私のコードへのレビューの順で支援する
- 私が「実装して」「答えを見せて」と明示したときだけ、完成物を出す。そのときも理由を説明する
- エラーは、まず読むべきログやコマンド（`kubectl describe`、`kubectl logs` など）を示して、一緒に切り分ける

## 固定するバージョン（着手時に調べて記入する）
- Kubernetes: 1.37 以上（kagent 1.0 の前提。kindest/node のタグは未確認）
- Kind: 未定
- Terraform: 1.17.2（2026-11-22 に Mac へ導入。公式の SHA256 を照合済み）
- gcloud: 594.0.0（2026-11-22 に Mac へ導入）
- Argo CD: 未定
- Istio: 未定（sidecar か ambient かも未定）
- vLLM（CPU 版イメージ）: 未定
- Agent Substrate: 未定
- kagent: 1.0 系（正確なバージョンは未定）
- agentgateway: 未定

バージョンは推測で書かない。公式のリリース情報を確認してから記入する。

## 運用ルール
- GCP の操作（VM 作成・削除、課金に関わる設定）は、内容を提示して承認を得てから実行する
- `git push`・ファイル削除・ファイル移動は、承認を得てから実行する
- 機密情報（キー、トークン、`.env`、kubeconfig）は読まない・書かない・コミットしない
- 使い終わった VM は停止する
- `gcloud projects delete`、`terraform apply`、`terraform destroy` の前に、対象と内容を確認する。`apply` の前は `plan` の結果を一緒に読む
- Terraform の状態ファイル（`*.tfstate`）と `*.tfvars` は、コミットしない・読まない
- 公開リポジトリには、GCP のプロジェクト ID、請求アカウント ID、メールアドレスを書かない
