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

variable "deny_paths" {
  description = "Urs paths to be denied"
  type        = list(string)
  default = [
    "/%0ASet-Cookie%3Acrlfinjection/..",
    "/en/./RestAPI/Connection",
    "/en/RestAPI/Connection",
    "/./RestAPI/LogonCustomization",
    "/RestAPI/LogonCustomization",
    "/RestAPI/Connection",
  ]
}
