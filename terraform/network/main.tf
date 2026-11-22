# 専用の VPC、サブネット、ファイアウォール、Cloud Router、Cloud NAT。

locals {
  # ファイアウォールのルールの対象になる、ネットワークタグ。
  # vm/ がこの値を受け取って、VM に付ける（outputs.tf で出力する）。定義は、ここ 1 か所だけにする。
  node_tag    = "k8s-node" # ノード同士の通信を許可するルールの対象
  iap_ssh_tag = "iap-ssh"  # IAP からの SSH を許可するルールの対象
}

# --- API の有効化 ---------------------------------------------------------
# disable_on_destroy = false: terraform destroy で、API まで無効にしない
# （他のリソースや、手作業で使っているものが、止まるのを防ぐ）。
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# IAP を使うための API。必要かどうかは、公式ドキュメントで確認する（不要なら消す）。
resource "google_project_service" "iap" {
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

# --- VPC とサブネット -----------------------------------------------------
# auto_create_subnetworks = false: サブネットを自動で作らず、自分で決めた範囲だけを作る。
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

# for_each で、var.subnets の数だけ作る。
# サブネットの名前に使えるのは、小文字、数字、ハイフンだけ。キーの _ を - に変える。
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name          = "${var.network_name}-${replace(each.key, "_", "-")}"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = each.value.ip_cidr_range
}

# --- ファイアウォール -----------------------------------------------------
# VPC には、入ってくる通信を拒否する暗黙のルールがある。許可したい通信だけを書く。

# IAP からの SSH（TCP 22）だけを許可する。対象は、iap-ssh のタグを付けた VM。
resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.network_name}-allow-iap-ssh"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"

  source_ranges = [var.iap_source_range]
  target_tags   = [local.iap_ssh_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ノード同士の通信を許可する。送信元も対象も、k8s-node のタグを付けた VM に限る。
# 最初は、tcp と udp の全ポートと icmp を許可して、構築のつまずきを減らす。
# kubeadm と CNI に必要なポートを確認したあとで、必要なものだけに絞る（学習の題材）。
resource "google_compute_firewall" "allow_internal_nodes" {
  name      = "${var.network_name}-allow-internal-nodes"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"

  source_tags = [local.node_tag]
  target_tags = [local.node_tag]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

# --- Cloud Router と Cloud NAT --------------------------------------------
# VM に外部 IP を付けない代わりに、外へ出る通信を Cloud NAT に任せる。
resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name   = "${var.network_name}-nat"
  router = google_compute_router.router.name
  region = var.region

  # NAT の外部 IP は、Google が自動で割り当てる。
  nat_ip_allocate_option = "AUTO_ONLY"

  # 指定したサブネットだけを、NAT の対象にする。
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # dynamic ブロック: サブネットの数だけ、subnetwork ブロックを作る。
  # サブネットを増やしても、ここを書き足さなくてよい。
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.this

    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}
