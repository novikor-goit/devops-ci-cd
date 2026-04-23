output "service_name" {
  description = "Jenkins LoadBalancer service name"
  value       = "jenkins"
}

output "namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "admin_password_cmd" {
  description = "Command to retrieve the Jenkins initial admin password"
  value       = "kubectl exec -n ${kubernetes_namespace.jenkins.metadata[0].name} svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}

