variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN used to encrypt the logs"
  type        = string
}

variable "cognito_code_template_id" {
  description = "Notify template id used by cognito"
  type        = string
}

variable "notify_api_key_secret_arn" {
  description = "GC Notify API key arn"
  type        = string
  sensitive   = true
}

variable "lambda_code_arn" {
  description = "S3 bucket arn for lambda code"
  type        = string
}

variable "lambda_code_id" {
  description = "S3 bucket id for lambda code"
  type        = string
}