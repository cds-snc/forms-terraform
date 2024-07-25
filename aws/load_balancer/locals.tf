locals {
  all_domains              = var.feature_flag_api ? concat(var.domains, [var.domain_api]) : var.domains
  cbs_satellite_bucket_arn = "arn:aws:s3:::${var.cbs_satellite_bucket_name}"
}
