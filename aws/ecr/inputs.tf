variable "cds_org_id" {
  description = "AWS CDS organization ID"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "The account ID to create resources in"
  type        = string
}