# k8s-kind-lab

Kind（Kubernetes in Docker）で K8s を一通り学ぶための学習用リポジトリ。
API サーバとワーカを動かし、LLM は外部 API ではなく vLLM（CPU）を使う。その先で Argo CD、Agent Substrate、kagent 1.0、agentgateway を動かす。

最終目標は kagent の OSS 活動に関わること。kagent 本体の改修は、別途フォークした `kagent` リポジトリで行う。このリポジトリは「動かして理解する」場所。

設計の全体像は [docs/design.html](docs/design.html) にある（ブラウザで開く。構成図、通信の流れ、設計判断、リスク、メモリ見積りを載せている）。

## 方針
- 実行環境は、最初から Google Cloud の VM（1 台）上の Kind。使うときだけ起動し、夜間は自動停止する
- GKE は使わない（常時課金を避ける）。GPU も使わない
- VM は小さく始め、メモリが必要になる段階の前に、停止中にマシンタイプを変える
- 予算アラートと VM の再現は、Terraform で行う（Terraform 1.17.2。状態ファイルはコミットしない）
- 入口は、先に Ingress で理解し、段階 4b で Istio に移行して違いを学ぶ
- Kind は control-plane 1 台と worker 3 台の案。worker-3 はエージェント用に専用化する（案。未決定）
- vLLM は CPU 版で、小さいモデルを使う
- kagent は 1.0 を使う。1.0 は Agent Substrate、PostgreSQL、Kubernetes 1.37 以上が前提
- LLM の通信は、段階 7 で agentgateway を通す（kgateway は使わない）
- マニフェストやアプリのコードは、自分で書く。詰まったら「ヒント → レビュー」の順で支援してもらう

## ロードマップ

| 段階 | テーマ | 置き場所 | 調べる用語 |
|---|---|---|---|
| 0 | 環境準備（VM、Docker、kind、kubectl、helm） | `docs/00-vm-setup.md` | Compute Engine、予算アラート、インスタンススケジュール、Remote SSH |
| 0b | Terraform（予算アラートを VM の前に作る。手で作った VM の再現） | `terraform/`（着手時に作る） | provider、ADC、google_project_service、google_billing_budget、state、plan / apply |
| 1 | K8s の基礎（control-plane、worker、Service、Ingress の観察） | `cluster/` `docs/01-k8s-basics.md` | kubeadm、static Pod、kubelet、kube-proxy、EndpointSlice、Ingress controller |
| 2 | vLLM（CPU）のデプロイ | `manifests/10-vllm/` | PVC、リソース requests / limits、readiness / liveness probe |
| 3 | API サーバとワーカ | `apps/` `manifests/20-api/` `30-worker/` `40-queue/` | ConfigMap、Secret、Job / CronJob、HPA |
| 4 | 運用の理解 | `manifests/90-policy/` | NetworkPolicy、RBAC、ResourceQuota、ローリングアップデート |
| 4b | Istio（Ingress から移行） | `manifests/50-istio/`（着手時に作る） | Gateway、VirtualService、mTLS、sidecar と ambient |
| 5 | Argo CD（GitOps） | `gitops/argocd/` `gitops/apps/` | Application、sync、App of Apps |
| 6a | PostgreSQL と Agent Substrate | `gitops/substrate/`（着手時に作る） | WorkerPool、gVisor、サンドボックス |
| 6b | kagent 1.0 | `gitops/kagent/` | Helm、AgentTemplate、Harness、ModelConfig、RemoteMCPServer |
| 7 | agentgateway | `gitops/agentgateway/`（着手時に作る） | Gateway API、HTTPRoute、バックエンド |

各段階の完了の目安は [docs/design.html](docs/design.html) を見る。進捗は、各段階のノートを `docs/` に書いて管理する。

## 段階 1 で観察すること
予想を書いてから実行し、結果と見比べる。

- A. Kind の正体（`docker ps` のノードと `kubectl get nodes` の対応）
- B. コントロールプレーン（`kube-system` の Pod、static Pod）
- C. Pod 作成の流れ（`describe` の Events を追う）
- D. ワーカ（kubelet と containerd。worker を止めたときの挙動）
- E. Service（ClusterIP の実体、CoreDNS）
- F. Ingress（2 つのアプリをパスで振り分ける）

## フォルダ構成

```
cluster/      Kind の設定、クラスタ作成・削除の手順
terraform/    予算アラート、VM の再現（段階 0b で作る。状態ファイルはコミットしない）
apps/         API サーバ（api/）とワーカ（worker/）のコードと Dockerfile
manifests/    段階 1〜4 で手書きするマニフェスト
gitops/       段階 5 以降。Argo CD が監視する場所
docs/         設計（design.html）、VM 手順書、学習ノート
```

## 公式ドキュメント
- Kubernetes: https://kubernetes.io/docs/home/
- Kind: https://kind.sigs.k8s.io/
- Argo CD: https://argo-cd.readthedocs.io/
- vLLM: https://docs.vllm.ai/
- kagent: https://kagent.dev/
- agentgateway: https://agentgateway.dev/
- Terraform（Google プロバイダー）: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Istio: https://istio.io/latest/docs/

## 注意
- 機密情報（API キー、トークン、`.env`、kubeconfig）はコミットしない
- Terraform の状態ファイル（`*.tfstate`）と `*.tfvars` はコミットしない（請求アカウント ID などが入る）
- GCP のプロジェクト ID や IP アドレスなどの実値は、公開する前に確認する
- Kind の Ingress は、インターネットに公開しない（SSH のポート転送で確認する）
- 使い終わった VM は停止する。不要なら削除する
