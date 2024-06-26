variable "account_id" {
  description = "The account ID to create resources in"
  type        = string
}

variable "cbs_satellite_bucket_name" {
  description = "(Required) Name of the Cloud Based Sensor S3 satellite bucket"
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

variable "domain_idp" {
  description = "The identity provider domain"
  type        = string
}

variable "domains" {
  description = "The application domains"
  type        = list(string)
}

variable "env" {
  description = "The current running environment"
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
}
