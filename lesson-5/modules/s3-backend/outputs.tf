output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_url" {
  description = "URL S3-бакета для стейтів"
  value       = "s3://${aws_s3_bucket.terraform_state.id}"
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = aws_dynamodb_table.terraform_locks.name
}

