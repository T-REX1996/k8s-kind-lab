# VM 1 台分の部品。kubeadm のノード（control-plane か worker）として使う。

resource "google_compute_instance" "this" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.tags
  labels       = var.labels

  # マシンタイプを変えるときに、VM を一度止める必要がある。
  # これを true にすると、Terraform が止めて、変更して、起動し直す。
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    # access_config を書かない。外部 IP を付けない、という意味。
    # 外へ出る通信は、Cloud NAT が受け持つ。
  }

  # OS Login を有効にする。SSH の鍵を、Google アカウントの権限で管理できる。
  metadata = {
    enable-oslogin = "TRUE"
  }

  # 自動停止のスケジュールなど。止め忘れによる課金を防ぐ。
  resource_policies = var.resource_policies

  # service_account ブロックを書かない。VM に、Google Cloud の API を呼ぶ権限を持たせない（最小権限）。
}
