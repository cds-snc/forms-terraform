variable "staging_account_id" {
  description = "Staging account ID"
  type        = string
}
variable "cds_org_id" {
  description = "AWS CDS organization ID"
  type        = string
  sensitive   = true
}
