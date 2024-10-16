variable "ecr_repository_url_load_testing_lambda" {
  description = "URL of the Load Testing Lambda ECR"
  type        = string
}

variable "lambda_submission_function_name" {
  description = "Name of the Submission Lambda function."
  type        = string
}

variable "load_testing_form_id" {
  description = "Form ID that will be used to generate, retrieve and confirm responses."
  type        = string
  sensitive   = true
}

variable "load_testing_form_private_key" {
  description = "Private key JSON of the form that will be used to authenticate the API requests.  This must be a key from the `var.load_testing_form_id` form."
  type        = string
  sensitive   = true
}

variable "load_testing_form_api_private_key" {
  description = "Private key JSON used by the API to perform access token introspection requests.  This corresponds to the Zitadel application created for the API."
  type        = string
  sensitive   = true
}
