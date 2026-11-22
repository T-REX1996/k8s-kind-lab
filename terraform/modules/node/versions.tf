# モジュールでは、プロバイダーの「設定」（project や region）は書かない。
# 呼び出し側（vm/）のプロバイダー設定を、そのまま使う。
# ここには、必要なプロバイダーの種類だけを書く。バージョンの下限だけにして、厳しく固定しない。
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}
