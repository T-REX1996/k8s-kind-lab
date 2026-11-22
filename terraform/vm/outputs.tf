output "nodes" {
  description = "ノードごとのゾーンと内部 IP。kubeadm の設定と、SSH で使う"
  value = {
    for name, node in module.node : name => {
      zone        = node.zone
      internal_ip = node.internal_ip
    }
  }
}
