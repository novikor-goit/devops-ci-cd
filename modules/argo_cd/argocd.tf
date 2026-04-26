resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "null_resource" "delete_argocd_lb" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete svc argocd-server -n argocd --ignore-not-found=true 2>/dev/null || true
      timeout 120 bash -c 'while kubectl get svc argocd-server -n argocd 2>/dev/null | grep -q LoadBalancer; do sleep 5; done' || true
      sleep 30
    EOT
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  create_namespace = false
  timeout          = 1200
  cleanup_on_fail  = true

  values = [file("${path.module}/values.yaml")]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${path.module}/charts"

  depends_on = [helm_release.argocd]
}
