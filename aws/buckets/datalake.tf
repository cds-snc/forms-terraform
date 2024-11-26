#
# Holds exported data from ETL transformations
#
module "lake_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v10.0.0"
  bucket_name       = "cds-data-lake-bucket-${var.env}"
  billing_tag_value = var.billing_tag_value

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "datalake/"
  }

  lifecycle_rule = [
    local.lifecycle_remove_noncurrent_versions,
    local.lifecycle_transition_storage
  ]

  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "lake_bucket" {
  bucket = module.lake_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.lake_bucket.json
}

#
# There is a 20kb limit on the size of the policy document
#
data "aws_iam_policy_document" "lake_bucket" {
  statement {
    sid    = "CostAndUsageReport"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::659087519042:role/BillingExtractTags",
        "arn:aws:iam::659087519042:role/CostUsageReplicateToDataLake"
      ]
    }
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:PutObject",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      module.lake_bucket.s3_bucket_arn,
      "${module.lake_bucket.s3_bucket_arn}/*"
    ]
  }
}