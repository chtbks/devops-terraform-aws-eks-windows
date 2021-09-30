resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = "kube-system"

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
}
