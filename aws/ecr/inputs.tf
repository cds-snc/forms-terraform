variable "cds_org_id" {
  description = "AWS CDS organization ID"
  type        = string
  sensitive   = true
}

variable "aws_development_accounts" {
  description = "List of AWS development account IDs"
  type        = list(string)
}
