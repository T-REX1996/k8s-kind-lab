variable "project_id" {
  description = "GCP のプロジェクト ID（実値は terraform.tfvars に書く。コミットしない）"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "network_name" {
  description = "VPC の名前。サブネットやファイアウォールの名前の先頭にも使う"
  type        = string
  default     = "k8s-lab-vpc"
}

# サブネットを map で定義する。for_each で、定義した数だけ作る。
# キーは、vm/ が参照する（control_plane と worker）。キーを変えると、vm/ の nodes の subnet も直す。
variable "subnets" {
  description = "サブネットの定義。キーは control_plane と worker"
  type = map(object({
    ip_cidr_range = string
  }))

  default = {
    control_plane = { ip_cidr_range = "10.10.0.0/27" }
    worker        = { ip_cidr_range = "10.10.0.32/27" }
  }

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.ip_cidr_range, 0))])
    error_message = "ip_cidr_range は、CIDR 形式（例: 10.10.0.0/27）で書く。"
  }

  validation {
    condition     = contains(keys(var.subnets), "control_plane") && contains(keys(var.subnets), "worker")
    error_message = "subnets には、control_plane と worker の 2 つのキーが必要。vm/ が、このキーで参照する。"
  }
}

variable "iap_source_range" {
  description = "IAP が SSH に使う送信元の範囲（Google が公開している値。公式ドキュメントで確認する）"
  type        = string
  default     = "35.235.240.0/20"

  validation {
    condition     = can(cidrhost(var.iap_source_range, 0))
    error_message = "iap_source_range は、CIDR 形式で書く。"
  }
}
