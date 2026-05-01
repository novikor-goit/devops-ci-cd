output "namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_port_forward_cmd" {
  description = "Command to access Grafana via port-forward"
  value       = "kubectl port-forward svc/grafana 3000:80 -n ${var.namespace}"
}

output "grafana_admin_password_cmd" {
  description = "Command to retrieve Grafana admin password from secret"
  value       = "kubectl get secret grafana -n ${var.namespace} -o jsonpath='{.data.admin-password}' | base64 -d"
}
