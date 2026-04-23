output "namespace" {
  description = "Namespace where Argo CD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "admin_password_cmd" {
  description = "Command to retrieve the Argo CD initial admin password"
  value       = "kubectl get secret argocd-initial-admin-secret -n ${kubernetes_namespace.argocd.metadata[0].name} -o jsonpath='{.data.password}' | base64 -d"
}

