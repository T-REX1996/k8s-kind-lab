# VM 3 台と、自動停止のスケジュール。

# network/ の出力を読む。network/ を先に apply しておく必要がある。
data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "network" # network/ の backend.tf の prefix と同じ
  }
}

locals {
  # network/ の出力を、短い名前で使えるようにする。
  network = data.terraform_remote_state.network.outputs
}

# --- 自動停止のスケジュール -----------------------------------------------
# 毎日決まった時刻に、VM を停止する。予算アラートがない間の、止め忘れ対策。
resource "google_compute_resource_policy" "auto_stop" {
  name   = "k8s-lab-auto-stop"
  region = var.region

  instance_schedule_policy {
    time_zone = var.time_zone

    vm_stop_schedule {
      schedule = var.stop_schedule
    }
  }
}

# スケジュールが VM を止めるには、Compute Engine のサービスエージェントに権限が要る。
# 公式ドキュメントで、必要なロールを確認する。
# このサービスエージェントは、Compute Engine の API を使い始めたあとにできる。
# 「サービスアカウントが存在しない」というエラーが出たら、VM を作ったあとで、もう一度 apply する。
data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_iam_member" "scheduler_agent" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:service-${data.google_project.this.number}@compute-system.iam.gserviceaccount.com"
}

# --- VM 3 台 --------------------------------------------------------------
# for_each で、var.nodes の数だけ、node モジュールを呼ぶ。
module "node" {
  source   = "../modules/node"
  for_each = var.nodes

  name         = each.key
  zone         = var.zone
  machine_type = each.value.machine_type
  disk_size_gb = each.value.disk_size_gb
  disk_type    = each.value.disk_type

  # network/ の出力から、サブネットを選ぶ（control_plane か worker）。
  subnetwork = local.network.subnet_self_links[each.value.subnet]

  # タグの名前は、network/ の出力から受け取る（ファイアウォールのルールと、必ず同じ値になる）。
  # 最後のタグは、役割（control-plane か worker）。
  tags = [local.network.node_tag, local.network.iap_ssh_tag, each.value.role]

  labels = {
    role = each.value.role
  }

  resource_policies = [google_compute_resource_policy.auto_stop.id]
}
