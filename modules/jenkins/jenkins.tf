resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version

  create_namespace = false
  timeout          = 1200
  cleanup_on_fail  = true

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "controller.admin.username"
    value = var.admin_user
  }

  set_sensitive {
    name  = "controller.admin.password"
    value = var.admin_password
  }
}
