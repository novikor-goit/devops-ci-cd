# Standard RDS outputs
output "db_endpoint" {
  description = "Endpoint підключення до стандартного RDS (порожній при use_aurora=true)"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].endpoint
}

output "db_port" {
  description = "Порт підключення до БД"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

# Aurora outputs
output "aurora_cluster_endpoint" {
  description = "Writer endpoint Aurora кластера (порожній при use_aurora=false)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint Aurora кластера (порожній при use_aurora=false)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

# Shared outputs
output "security_group_id" {
  description = "ID Security Group, прикріпленої до БД"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Назва DB Subnet Group"
  value       = aws_db_subnet_group.default.name
}

output "db_name" {
  description = "Назва бази даних"
  value       = var.db_name
}
