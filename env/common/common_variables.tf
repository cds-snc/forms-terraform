variable "account_id" {
  description = "The account ID to create resources in"
  type        = string
}

variable "billing_tag_key" {
  description = "The default tagging key"
  type        = string
}

variable "billing_tag_value" {
  description = "The default tagging value"
  type        = string
}

variable "domain" {
  description = "The server domain"
  type        = string
}

variable "env" {
  description = "The current running environment"
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
}
