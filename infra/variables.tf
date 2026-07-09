variable "region" {
  description = "Regiao AWS mockada"
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "Endpoint do LocalStack na rede Docker"
  type        = string
  default     = "http://localstack:4566"
}

variable "bucket_name" {
  description = "Nome do bucket S3 para artefatos"
  type        = string
  default     = "techmind-content"
}

variable "secret_name" {
  description = "Nome do secret no Secrets Manager"
  type        = string
  default     = "techmind/db-credentials"
}

variable "db_credentials" {
  description = "JSON com credenciais do PostgreSQL"
  type        = map(string)
  default = {
    host     = "postgres"
    port     = "5432"
    username = "techmind"
    password = "techmind_dev"
    dbname   = "techmind_dev"
  }
}
