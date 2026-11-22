variable "project_id" {
  description = "GCP のプロジェクト ID（実値は terraform.tfvars に書く。コミットしない）"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "VM を置くゾーン（3 台とも同じ）。別のマシンの系列を使うときは、そのゾーンで提供されているか確認する"
  type        = string
  default     = "asia-northeast1-a"
}

variable "state_bucket" {
  description = "network/ の状態ファイルがあるバケット名。terraform_remote_state で、network/ の出力を読むために使う"
  type        = string
}

variable "stop_schedule" {
  description = "自動停止の時刻（cron 形式）。止め忘れによる課金を防ぐ"
  type        = string
  default     = "0 23 * * *"
}

variable "time_zone" {
  description = "自動停止のタイムゾーン"
  type        = string
  default     = "Asia/Tokyo"
}

# ノードの定義。VM の数や大きさは、ここを変えるだけで変えられる。
# サイズは、最初は小さく始める。ディスクは、増やせるが減らせない。
variable "nodes" {
  description = "ノード（VM）の定義。キーが VM の名前になる"
  type = map(object({
    role         = string # control-plane か worker
    subnet       = string # network/ の出力のキー: control_plane か worker
    machine_type = string
    disk_size_gb = number
    disk_type    = string
  }))

  default = {
    "k8s-cp-1" = {
      role         = "control-plane"
      subnet       = "control_plane"
      machine_type = "e2-medium"
      disk_size_gb = 30
      disk_type    = "pd-balanced" # etcd は、ディスクの書き込みが遅いと不安定になる
    }
    "k8s-worker-1" = {
      role         = "worker"
      subnet       = "worker"
      machine_type = "e2-medium"
      disk_size_gb = 40
      disk_type    = "pd-balanced"
    }
    "k8s-worker-2" = {
      role         = "worker"
      subnet       = "worker"
      machine_type = "e2-medium"
      disk_size_gb = 50
      disk_type    = "pd-balanced"
    }
  }

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["control-plane", "worker"], n.role)])
    error_message = "role は、control-plane か worker にする。"
  }

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["control_plane", "worker"], n.subnet)])
    error_message = "subnet は、control_plane か worker にする（network/ の subnets のキーと同じ）。"
  }

  validation {
    condition     = length([for n in values(var.nodes) : n if n.role == "control-plane"]) == 1
    error_message = "control-plane は、ちょうど 1 台にする。"
  }
}
