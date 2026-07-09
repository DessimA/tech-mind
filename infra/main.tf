# Bucket S3 para artefatos
resource "aws_s3_bucket" "techmind_content" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "techmind_content" {
  bucket = aws_s3_bucket.techmind_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Secret para credenciais do PostgreSQL
resource "aws_secretsmanager_secret" "db_credentials" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode(var.db_credentials)
}
