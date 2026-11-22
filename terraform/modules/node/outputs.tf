# 呼び出し側（vm/）が実際に使う値だけを出す。リソースを丸ごと出さない。

output "name" {
  description = "VM の名前"
  value       = google_compute_instance.this.name
}

output "zone" {
  description = "VM のゾーン"
  value       = google_compute_instance.this.zone
}

output "internal_ip" {
  description = "VM の内部 IP。ノード間の通信と、kubeadm の設定で使う"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "self_link" {
  description = "VM の self_link"
  value       = google_compute_instance.this.self_link
}
