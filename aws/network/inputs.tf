variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN used to encrypt the VPC flow logs"
  type        = string
}

variable "vpc_cidr_block" {
  description = "IP CIDR block of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}
