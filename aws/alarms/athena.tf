#
# Create Athena queries to view the WAF and load balancer access logs
#
module "athena" {
  source = "github.com/cds-snc/terraform-modules?ref=v6.1.1//athena_access_logs"

  athena_bucket_name = module.athena_bucket.s3_bucket_id

  lb_access_queries_create   = true
  lb_access_log_bucket_name  = var.cbs_satellite_bucket_name
  waf_access_queries_create  = true
  waf_access_log_bucket_name = var.cbs_satellite_bucket_name

  billing_tag_value = var.billing_tag_value
}

#
# Hold the Athena data
#
module "athena_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v6.1.1//S3"
  bucket_name       = "forms-${var.env}-athena-bucket"
  billing_tag_value = var.billing_tag_value

  lifecycle_rule = [
    {
      id      = "expire-objects-after-7-days"
      enabled = true
      expiration = {
        days                         = 7
        expired_object_delete_marker = false
      }
    },
  ]
}
