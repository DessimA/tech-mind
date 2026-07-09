output "bucket_id" {
  description = "ID do bucket S3"
  value       = aws_s3_bucket.techmind_content.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.techmind_content.arn
}

output "secret_id" {
  description = "ID/ARN do secret no Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "secret_arn" {
  description = "ARN do secret no Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
