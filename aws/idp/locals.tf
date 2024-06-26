locals {
  hosted_zone_id = var.hosted_zone_ids[0]
  common_tags = {
    Terraform             = "true"
    (var.billing_tag_key) = var.billing_tag_value
  }
}
