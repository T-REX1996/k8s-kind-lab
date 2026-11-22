# network/ とは別の prefix にする。バケット名は backend.hcl から渡す（コミットしない）。
#   terraform init -backend-config=backend.hcl
terraform {
  backend "gcs" {
    prefix = "vm"
  }
}
