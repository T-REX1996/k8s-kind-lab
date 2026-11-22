# terraform/

kubeadm 用の VM とネットワークを作る Terraform。設計は [docs/design.html](../docs/design.html)、手順書は [docs/00-vm-setup.md](../docs/00-vm-setup.md)。

```
terraform/
├── modules/node/   VM 1 台分の部品（vm/ から for_each で 3 回呼ぶ）
├── network/        VPC、サブネット 2 つ、ファイアウォール、Cloud Router、Cloud NAT
└── vm/             VM 3 台と自動停止のスケジュール
```

## 順番

- 作る: `network/` → `vm/`
- 消す: `vm/` → `network/`（逆の順番）

## 初回の準備（フォルダごとに行う）

1. `terraform.tfvars.example` をコピーして `terraform.tfvars` を作り、実値を書く
2. `backend.hcl.example` をコピーして `backend.hcl` を作り、状態ファイル用のバケット名を書く
3. 認証は、`gcloud auth application-default login`（ADC）

`terraform.tfvars` と `backend.hcl` は、実値が入るので、**コミットしない**（`.gitignore` で除外済み）。

## コマンドの流れ

```
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

- `apply` の前に、必ず `plan` の結果を読む（台数、マシンタイプ、ディスク、外部 IP）
- `apply` を実行すると、VM などの課金が始まる。使い終わったら、停止する。長く使わないときは、`destroy` する
- `terraform destroy` の前に、対象を確認する

## 注意

- 状態ファイルは GCS のバケットにある。バケットは、Terraform ではなく、手作業（gcloud）で作った。公開しない。バージョニングを有効にしてある
- `.terraform.lock.hcl` は、コミットする（プロバイダーのバージョンを固定するため）
- プロバイダーは `~> 6.0`。最新は 8 系だが、書き方に慣れている 6 系を指定している
- ゾーンは `asia-northeast1-a`（決定）。マシンタイプ、ディスクの種類は、仮の値。確認してから決める
