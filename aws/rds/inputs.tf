variable "private_subnet_ids" {
  description = "The list of private subnet IDs to attach the RDS cluster to"
  type        = list(string)
}

variable "rds_db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "rds_connector_db_user" {
  description = "The username the RDS connector uses to connect to the database"
  type        = string
}

variable "rds_connector_db_password" {
  description = "The password the RDS connector uses to connect to the database"
  type        = string
  sensitive   = true
}

variable "rds_db_user" {
  description = "The username of the RDS database"
  type        = string
}

variable "rds_db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "rds_db_subnet_group_name" {
  description = "The name of the RDS database subnet group"
  type        = string
}

variable "rds_name" {
  description = "The name of the RDS cluster"
  type        = string
}

variable "rds_security_group_id" {
  description = "The security group used by Redis"
  type        = string
}

variable "localstack_hosted" {
  description = "Whether or not the stack is hosted in localstack"
  type        = bool
}
