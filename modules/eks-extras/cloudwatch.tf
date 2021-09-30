resource "kubernetes_namespace" "fluent_bit" {
  metadata {
    name = local.fluent_bit_namespace
  }
}

resource "helm_release" "fluent_bit_daemonset" {
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"

  name      = "fluent-bit"
  namespace = kubernetes_namespace.fluent_bit.metadata[0].name

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
  set {
    name  = "nodeSelector.kubernetes\\.io/arch"
    value = "x64"
  }
  set {
    name  = "config.outputs"
    value = templatefile("${path.module}/templates/output.conf", { aws_region = data.aws_region.current.name })
  }
  set {
    name  = "config.parsers"
    value = file("${path.module}/templates/parsers.conf")
  }
  set {
    name  = "config.customParsers"
    value = file("${path.module}/templates/filters.conf")
  }
}
