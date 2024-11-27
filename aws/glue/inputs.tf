variable "rds_cluster_endpoint" {
  description = "The endpoint of the RDS database"
  type        = string
}

variable "rds_db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "rds_db_user" {
  description = "The user of the RDS database"
  type        = string
}

variable "rds_db_password" {
  description = "The password of the RDS database"
  type        = string
}

variable "datalake_bucket_arn" {
  description = "The ARN of the Raw bucket"
  type        = string
}

variable "datalake_bucket_name" {
  description = "The name of the Raw bucket"
  type        = string
}

variable "etl_bucket_name" {
  description = "The name of the ETL bucket"
  type        = string
}

variable "s3_endpoint" {
  description = "The S3 endpoint"
  type        = string
}