# k8s-kind-lab

Kind（Kubernetes in Docker）で K8s を一通り学ぶための学習用リポジトリ。
API サーバとワーカを動かし、LLM は外部 API ではなく vLLM（CPU）を使う。最終的に Argo CD と kagent も動かす。

最終目標は kagent の OSS 活動に関わること。kagent 本体の改修は、別途フォークした `kagent` リポジトリで行う。このリポジトリは「動かして理解する」場所。

## 方針
- 実行環境は Google Cloud の VM（1 台）上の Kind。使うときだけ起動し、夜間は自動停止する
- GKE は使わない（常時課金を避ける）
- GPU なし。vLLM は CPU 版で、小さいモデルを使う
- マニフェストやアプリのコードは、自分で書く。詰まったら「ヒント → レビュー」の順で支援してもらう

## ロードマップ

| 段階 | テーマ | 置き場所 | 調べる用語 |
|---|---|---|---|
| 0 | 環境準備（VM、Docker、kind、kubectl、helm） | `docs/` | GCE、インスタンススケジュール、Remote SSH |
| 1 | K8s の基礎 | `cluster/` `manifests/00-namespace/` | Pod、Deployment、Service、Namespace、kind の config |
| 2 | vLLM（CPU）のデプロイ | `manifests/10-vllm/` | PVC、リソース requests / limits、readiness / liveness probe |
| 3 | API サーバとワーカ | `apps/` `manifests/20-api/` `30-worker/` `40-queue/` | ConfigMap、Secret、Ingress、Job / CronJob、HPA |
| 4 | 運用の理解 | `manifests/90-policy/` | NetworkPolicy、RBAC、ResourceQuota、ローリングアップデート |
| 5 | Argo CD（GitOps） | `gitops/argocd/` `gitops/apps/` | Application、sync、App of Apps |
| 6 | kagent を動かす | `gitops/kagent/` | Helm、Agent、ModelConfig、OpenAI 互換エンドポイント |

進捗は、各段階のノートを `docs/` に書いて管理する。

## フォルダ構成

```
cluster/      Kind の設定、クラスタ作成・削除のショートカット
apps/         API サーバ（api/）とワーカ（worker/）のコードと Dockerfile
manifests/    段階 1〜4 で手書きするマニフェスト
gitops/       段階 5 以降。Argo CD が監視する場所
docs/         学習ノート、VM 手順書
```

## 公式ドキュメント
- Kubernetes: https://kubernetes.io/docs/home/
- Kind: https://kind.sigs.k8s.io/
- Argo CD: https://argo-cd.readthedocs.io/
- vLLM: https://docs.vllm.ai/
- kagent: https://kagent.dev/

## 注意
- 機密情報（API キー、トークン、`.env`、kubeconfig）はコミットしない
- GCP のプロジェクト ID や IP アドレスなどの実値は、公開する前に確認する
- 使い終わった VM は停止する。不要なら削除する
