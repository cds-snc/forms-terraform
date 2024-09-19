locals {
  all_domains              = concat(var.domains, [var.domain_api])
  cbs_satellite_bucket_arn = "arn:aws:s3:::${var.cbs_satellite_bucket_name}"
}
