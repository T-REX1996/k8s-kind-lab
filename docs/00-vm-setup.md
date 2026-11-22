# 段階 0・0b: VM とネットワークの準備（Terraform）

Google Cloud に、専用の VPC と VM 3 台を、Terraform で作る。VM の上に、kubeadm でクラスタを作る（段階 1）。
このファイルは、決めたこと、実行した手順、つまずいた点を、**自分で書いて**残す場所。決まっていることだけを書き、手順の中身は空にしてある。記事にできる形で書く。

関連: [設計方針](design.html)（段階 0・0b）

## 状態

- [ ] 決めること（下の表）をすべて決めた
- [ ] 手順 0-1〜0-6 を終えた
- [ ] この手順書を見て、VM とネットワークを作り直せる

## 前提（済み）

- [x] Mac に gcloud と Terraform を入れた
- [x] `gcloud auth login` を済ませた
- [x] GCP のプロジェクトを作った（組織の下）。請求を紐付けた
- [x] `gcloud auth application-default login`（Terraform が使う認証）
- [x] tfstate 用の GCS バケットを、手作業（gcloud）で作った（東京、非公開、バージョニング有効）。バケット名は、`terraform/*/backend.hcl`（コミットしない）にある
- [ ] 予算アラート（見送り中。作るときは、Terraform で）

> 公開するもの（このリポジトリ、ブログ）に、プロジェクト ID、請求アカウント ID、組織 ID、メールアドレス、IP アドレスを書かない。

## 1. 決めること

調べて決めた理由も、一言ずつ書く。

| 項目 | 決めたこと | 理由・調べた先 |
|---|---|---|
| クラスタの作り方 | kubeadm（Kind は使わない） | |
| ノードの台数 | control-plane 1 台と worker 2 台 | |
| サブネット | 2 つに分ける。control-plane 用 `10.10.0.0/27`、worker 用 `10.10.0.32/27` | |
| 外へ出る方法 | Cloud NAT（VM に外部 IP は付けない） | |
| SSH | IAP 経由だけ | |
| マシンタイプ（ノードごと。最初は小さく） | 各ノード 2 vCPU / 4 GB 前後から始める。具体的なタイプは未定 | |
| リージョン・ゾーン（3 台とも同じゾーン） | リージョンは東京（`asia-northeast1`）。ゾーンは `asia-northeast1-a`（3 台とも同じ） | |
| OS（Ubuntu の LTS、x86_64） | | |
| ディスクの種類とサイズ（ノードごと） | サイズの目安: control-plane 20〜30 GB、worker-1 30〜50 GB、worker-2 50〜100 GB（最初は小さく作り、増やすときは後から増やす。減らせない）。種類は未定 | OS、etcd、コンテナのイメージ。worker-2 は vLLM のイメージとモデルが大きい |
| 内部 IP を予約するか | | |
| 自動停止の時刻 | | |
| スポット VM を使うか（最初は通常の VM） | | |

調べる用語: マシンタイプ、リージョンとゾーン、永続ディスク、OS Login、インスタンススケジュール、Cloud Router、Cloud NAT

## 2. 手順

各手順に、実行したコマンドと、確認した結果を書く（コマンドに、ID などの実値が入る場合は、伏せる）。

### 0-1. 認証

- [ ] `gcloud auth application-default login` を済ませた
- [ ] 使うプロジェクトが、gcloud の既定になっている

メモ:

### 0-2. ネットワークを作る（Terraform）

- [ ] 専用の VPC（サブネットを自動で作らない）
- [ ] サブネット 2 つ: control-plane 用 `10.10.0.0/27`、worker 用 `10.10.0.32/27`
- [ ] ファイアウォール: IAP の範囲から TCP 22 だけを許可
- [ ] ファイアウォール: ノード同士の通信を許可（ネットワークタグ `control-plane`、`worker` で絞る）
- [ ] Cloud Router と Cloud NAT（**2 つのサブネットの両方**を対象にした）
- [ ] `terraform plan` の結果を読んでから `apply` した

実行したこと:

確認した結果:

調べる用語: google_compute_network、google_compute_subnetwork、google_compute_firewall、google_compute_router、google_compute_router_nat、IAP の範囲、kubeadm に必要なポート

### 0-3. VM を作る（Terraform）

- [ ] Compute Engine の API を有効にした
- [ ] VM 3 台（外部 IP なし、OS Login、タグ）
- [ ] **自動停止のスケジュールを、同じコードに入れた**
- [ ] `terraform plan` の結果を読んでから `apply` した（台数、マシンタイプ、ディスク、外部 IP を確認）

実行したこと:

確認した結果:

調べる用語: google_project_service、google_compute_instance、google_compute_resource_policy、instance_schedule_policy、必要な権限

### 0-4. SSH でつなぐ

- [ ] IAP 経由で、3 台すべてに SSH できた
- [ ] VS Code の Remote SSH でつながった
- [ ] ファイアウォールを、不必要に開けていない

実行したこと:

確認した結果:

調べる用語: IAP TCP forwarding、OS Login、SSH config、`gcloud compute config-ssh`

### 0-5. 疎通を確認する

- [ ] ノード同士で通信できる（内部 IP）
- [ ] Cloud NAT 経由で、外に出られる（パッケージの取得）
- [ ] 自動停止が動くことを確認した

実行したこと:

確認した結果:

### 0-6. 作り直せることを確認する

- [ ] `terraform destroy` で消せた（実行前に、対象を確認した）
- [ ] もう一度 `apply` して、同じ状態に戻せた

実行したこと:

確認した結果:

## 3. つまずいたこと

| 日付 | 症状（エラーの要点） | 原因 | 直し方 |
|---|---|---|---|
| | | | |

## 4. 作り直す手順（メモ）

VM とネットワークを消して作り直すときに、最低限必要な手順を、ここに短く書く。

## 5. 後片付け

- [ ] 使い終わった VM を停止した（3 台とも）
- [ ] 長く使わないときは、Terraform で消した（削除の前に、対象を確認する）
- [ ] 課金が発生していないことを、コンソールで確認した

## 6. 次に進む前の確認

- [ ] `docs/01-kubeadm-basics.md` を作る準備ができた
- [ ] Kubernetes 1.37 以上の kubeadm のパッケージが使えるか確認した
- [ ] この手順書を、レビューしてもらった
- [ ] 記事にできそうな点（つまずき、予想と結果の違い）を、メモした
