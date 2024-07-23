locals {
  all_domains                    = var.feature_flag_api ? concat(var.domains, [var.domain_api]) : var.domains
  app_primary_domain             = var.domains[0]
  cert_subject_alternative_names = setsubtract(local.all_domains, [local.app_primary_domain])

  cbs_satellite_bucket_arn = "arn:aws:s3:::${var.cbs_satellite_bucket_name}"
}
