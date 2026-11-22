# 状態ファイルを、GCS のバケットに置く。
# backend ブロックには、変数が使えない。そのため、バケット名はここに書かず、
# backend.hcl（コミットしない）から渡す:  terraform init -backend-config=backend.hcl
# prefix は、バケットの中のフォルダ名。network/ と vm/ で別の名前にする。
terraform {
  backend "gcs" {
    prefix = "network"
  }
}
