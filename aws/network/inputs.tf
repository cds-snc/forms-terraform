variable "vpc_cidr_block" {
  description = "IP CIDR block of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "KMS key for cloudwatch logs"
  type        = string
}