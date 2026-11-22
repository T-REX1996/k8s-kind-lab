# k8s-kind-lab

Google Cloud の VM 3 台に kubeadm で K8s のクラスタを作り、一通り学ぶための学習用リポジトリ。
API サーバとワーカを動かし、LLM は外部 API ではなく vLLM（CPU）を使う。その先で Istio、Argo CD、Agent Substrate、kagent 1.0、agentgateway を動かす。

最終目標は kagent の OSS 活動に関わることと、学んだことを Zenn の記事にすること。kagent 本体の改修は、別途フォークした `kagent` リポジトリで行う。このリポジトリは「動かして理解する」場所。

> リポジトリ名は `k8s-kind-lab` のまま。クラスタを Kind から kubeadm に変えたので、名前を変えるかは未定。

設計の全体像は [docs/design.html](docs/design.html) にある（ブラウザで開く。構成図、通信の流れ、設計判断、リスク、メモリ見積りを載せている）。

## 方針
- クラスタは kubeadm で、本物の VM に作る。Kind は使わない
- VM は 3 台（control-plane 1 台と worker 2 台）。Terraform でネットワークと VM を作り、作り直せるようにする
- ネットワークは専用の VPC。サブネットは 2 つに分け、control-plane 用が `10.10.0.0/27`、worker 用が `10.10.0.32/27`。3 台とも同じゾーンに置く
- VM に外部 IP は付けず、外へは Cloud NAT で出る（2 つのサブネットの両方が対象）
- SSH は IAP 経由だけ。公開するポートはなし。画面は IAP のポート転送で見る
- GKE は使わない（常時課金を避ける）。GPU も使わない
- VM は小さく始め、メモリが必要になる段階の前に、停止中にマシンタイプを変える
- 自動停止のスケジュールを、VM と同じコードに入れる。予算アラートは見送り中
- vLLM は CPU 版で、小さいモデルを使う
- kagent は 1.0 を使う。1.0 は Agent Substrate、PostgreSQL、Kubernetes 1.37 以上が前提
- 入口は、先に Ingress で理解し、段階 4b で Istio に移行して違いを学ぶ
- LLM の通信は、段階 7 で agentgateway を通す（kgateway は使わない）
- マニフェストやアプリのコードは、自分で書く。詰まったら「ヒント → レビュー」の順で支援してもらう
- 学んだことは、Zenn の記事にする（実値は書かない）

## ロードマップ

| 段階 | テーマ | 置き場所 | 調べる用語 |
|---|---|---|---|
| 0 | 環境準備（Mac の gcloud、Terraform、ログイン） | `docs/00-vm-setup.md` | gcloud CLI、ADC、プロジェクト、請求 |
| 0b | Terraform で VM とネットワーク（VPC、ファイアウォール、Cloud NAT、VM 3 台、自動停止） | `terraform/`（着手時に作る） | google_compute_network、router_nat、resource_policy、IAP |
| 1 | kubeadm でクラスタを作り、仕組みを観察する | `cluster/` `docs/01-kubeadm-basics.md` | kubeadm init / join、static Pod、CNI、kubelet、kube-proxy、Ingress controller |
| 1b | 運用演習（任意）。etcd のバックアップ、アップグレード、ノードの追加 | `docs/` | etcd snapshot、kubeadm upgrade |
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

- A. 前提の設定（swap、カーネルモジュール、sysctl、containerd）
- B. `kubeadm init` の中身（static Pod、証明書、kubeconfig）
- C. CNI の前後（NotReady から Ready へ）
- D. `join`（worker が参加する仕組み）
- E. Pod 作成の流れ（`describe` の Events を追う）
- F. Service（ClusterIP の実体、CoreDNS）
- G. Ingress（2 つのアプリをパスで振り分ける。入口は NodePort）
- H. 障害の観察（worker の VM を止める。VM を止めて起動し直す）

## フォルダ構成

```
terraform/    ネットワークと VM（段階 0b で作る。状態ファイルはコミットしない）
cluster/      kubeadm の設定、CNI のマニフェスト、前提設定の手順
apps/         API サーバ（api/）とワーカ（worker/）のコードと Dockerfile
manifests/    段階 2〜4b で手書きするマニフェスト
gitops/       段階 5 以降。Argo CD が監視する場所
docs/         設計（design.html）、VM 手順書、学習ノート（記事の種）
```

## 公式ドキュメント
- Kubernetes（kubeadm）: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- Kubernetes: https://kubernetes.io/docs/home/
- Terraform（Google プロバイダー）: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Google Cloud（IAP、Cloud NAT）: https://cloud.google.com/docs
- Istio: https://istio.io/latest/docs/
- Argo CD: https://argo-cd.readthedocs.io/
- vLLM: https://docs.vllm.ai/
- kagent: https://kagent.dev/
- agentgateway: https://agentgateway.dev/

## 注意
- 機密情報（API キー、トークン、`.env`、kubeconfig）はコミットしない
- Terraform の状態ファイル（`*.tfstate`）と `*.tfvars` はコミットしない（請求アカウント ID などが入る）
- GCP のプロジェクト ID、請求アカウント ID、メールアドレス、IP アドレスなどの実値は、公開するもの（このリポジトリ、ブログ）に書かない
- ノードは、インターネットに公開しない（SSH は IAP 経由、画面は IAP のポート転送で確認する）
- 使い終わった VM は停止する。長く使わないときは、Terraform で消す
