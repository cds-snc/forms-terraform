variable "ecr_repository_url_load_testing_lambda" {
  description = "URL of the Load Testing Lambda ECR"
  type        = string
}

variable "lambda_submission_function_name" {
  description = "Name of the Submission Lambda function."
  type        = string
}

variable "load_testing_zitadel_app_private_key" {
  description = "Private key JSON of the Zitadel application to perform access token introspection requests."
  type        = string
  sensitive   = true
}
