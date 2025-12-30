locals {
  cbs_satellite_bucket_arn = "arn:aws:s3:::${var.cbs_satellite_bucket_name}"
  api_domains              = [for domain in var.domains : "api.${domain}"]
  all_domains              = concat(var.domains, local.api_domains)

}
