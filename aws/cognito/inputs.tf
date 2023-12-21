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