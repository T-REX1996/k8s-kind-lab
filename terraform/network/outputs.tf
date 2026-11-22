# vm/ が、terraform_remote_state で、この出力を読む。

output "network_name" {
  description = "VPC の名前"
  value       = google_compute_network.vpc.name
}

output "subnet_self_links" {
  description = "サブネットの self_link。キーは var.subnets のキー（control_plane と worker）"
  value       = { for key, subnet in google_compute_subnetwork.this : key => subnet.self_link }
}

output "node_tag" {
  description = "ノード同士の通信を許可するルールの対象になるタグ。VM に付ける"
  value       = local.node_tag
}

output "iap_ssh_tag" {
  description = "IAP からの SSH を許可するルールの対象になるタグ。VM に付ける"
  value       = local.iap_ssh_tag
}

output "nat_name" {
  description = "Cloud NAT の名前"
  value       = google_compute_router_nat.nat.name
}
