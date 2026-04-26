resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "null_resource" "delete_jenkins_lb" {
  depends_on = [helm_release.jenkins]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete svc jenkins -n jenkins --ignore-not-found=true 2>/dev/null || true
      timeout 120 bash -c 'while kubectl get svc jenkins -n jenkins 2>/dev/null | grep -q LoadBalancer; do sleep 5; done' || true
      sleep 30
    EOT
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
