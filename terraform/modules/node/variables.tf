# VM 1 台分の入力。プロジェクトとリージョンは、中に書かず、プロバイダーの設定から受け取る。

variable "name" {
  description = "VM の名前"
  type        = string
}

variable "zone" {
  description = "VM を置くゾーン。3 台とも同じゾーンにすると、ノード間の通信が無料になる"
  type        = string
}

variable "machine_type" {
  description = "マシンタイプ（例: e2-medium）"
  type        = string
}

variable "disk_size_gb" {
  description = "起動ディスクのサイズ（GB）。後から増やせるが、減らせない"
  type        = number

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb は、10 以上にする（OS のイメージが入らない）。"
  }
}

variable "disk_type" {
  description = "起動ディスクの種類（pd-balanced、pd-standard、pd-ssd）。etcd のため、control-plane は pd-balanced 以上にする"
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.disk_type)
    error_message = "disk_type は、pd-standard、pd-balanced、pd-ssd のどれかにする。"
  }
}

variable "image" {
  description = "起動ディスクのイメージ（イメージファミリーを指定すると、その時点の最新が使われる）"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "subnetwork" {
  description = "VM をつなぐサブネットの self_link（または名前）"
  type        = string
}

variable "tags" {
  description = "ネットワークタグ。ファイアウォールのルールの対象になる"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "ラベル（課金の集計や、探しやすさのため）"
  type        = map(string)
  default     = {}
}

variable "resource_policies" {
  description = "VM に付けるリソースポリシー（自動停止のスケジュールなど）。最大 1 つ"
  type        = list(string)
  default     = []
}
