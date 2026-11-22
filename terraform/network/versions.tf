# Terraform とプロバイダーのバージョンを固定する。
# 実際に選ばれた版は、.terraform.lock.hcl に記録される（このファイルはコミットする）。
terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source = "hashicorp/google"
      # 最新は 8 系だが、書き方に慣れている 6 系を指定する。8 系への更新は、後の練習にできる。
      version = "~> 6.0"
    }
  }
}
