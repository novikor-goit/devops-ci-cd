output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3_backend.s3_bucket_name
}

output "s3_bucket_url" {
  description = "URL S3-бакета для стейтів"
  value       = module.s3_backend.s3_bucket_url
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "ID створеної VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Список ID публічних підмереж"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Список ID приватних підмереж"
  value       = module.vpc.private_subnets
}

output "ecr_repository_url" {
  description = "URL репозиторію ECR"
  value       = module.ecr.repository_url
}

output "jenkins_url" {
  description = "Jenkins LoadBalancer URL (run after apply to get EXTERNAL-IP)"
  value       = "kubectl get svc jenkins -n ${module.jenkins.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "jenkins_admin_password_cmd" {
  description = "Command to retrieve Jenkins admin password"
  value       = module.jenkins.admin_password_cmd
}

output "argocd_url" {
  description = "Argo CD LoadBalancer URL (run after apply to get EXTERNAL-IP)"
  value       = "kubectl get svc argo-cd-argocd-server -n ${module.argo_cd.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_admin_password_cmd" {
  description = "Command to retrieve Argo CD initial admin password"
  value       = module.argo_cd.admin_password_cmd
}

output "rds_db_endpoint" {
  description = "Endpoint стандартного RDS (null при use_aurora=true)"
  value       = module.rds.db_endpoint
}

output "rds_aurora_cluster_endpoint" {
  description = "Writer endpoint Aurora кластера (null при use_aurora=false)"
  value       = module.rds.aurora_cluster_endpoint
}

output "rds_aurora_reader_endpoint" {
  description = "Reader endpoint Aurora кластера (null при use_aurora=false)"
  value       = module.rds.aurora_reader_endpoint
}

output "rds_db_port" {
  description = "Порт підключення до БД"
  value       = module.rds.db_port
}

output "rds_security_group_id" {
  description = "ID Security Group БД"
  value       = module.rds.security_group_id
}

output "rds_db_name" {
  description = "Назва бази даних"
  value       = module.rds.db_name
}

output "grafana_port_forward_cmd" {
  description = "Command to access Grafana via port-forward"
  value       = module.monitoring.grafana_port_forward_cmd
}

output "grafana_admin_password_cmd" {
  description = "Command to retrieve Grafana admin password"
  value       = module.monitoring.grafana_admin_password_cmd
}
