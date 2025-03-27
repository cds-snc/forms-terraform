variable "rds_cluster_reader_endpoint" {
  description = "The endpoint of the RDS database"
  type        = string
}

variable "rds_port" {
  description = "The port of the RDS database"
  type        = string
}

variable "rds_db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "rds_cluster_instance_availability_zone" {
  description = "The RDS cluster instance's availability zone"
  type        = string
}

variable "rds_cluster_instance_identifier" {
  description = "The RDS cluster instance's identifier"
  type        = string
}

variable "rds_cluster_instance_subnet_id" {
  description = "The RDS cluster instance's subnet ID"
  type        = string
}

variable "rds_connector_secret_arn" {
  description = "The ARN of the RDS secret that contains the database authentication credentials"
  type        = string
}

variable "rds_connector_secret_name" {
  description = "The name of the RDS secret that contains the database authentication credentials"
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

variable "etl_bucket_arn" {
  description = "The ARN of the ETL bucket"
  type        = string
}

variable "etl_bucket_name" {
  description = "The name of the ETL bucket"
  type        = string
}

variable "glue_job_security_group_id" {
  description = "The security group ID for the Glue job"
  type        = string
}

variable "s3_endpoint" {
  description = "The S3 endpoint"
  type        = string
}

variable "submission_cloudwatch_endpoint" {
  description = "The name of the CloudWatch log group that handles submissions"
  type        = string
}