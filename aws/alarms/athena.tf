#
# Create Athena queries to view the WAF and load balancer access logs
#
module "athena" {
  source = "github.com/cds-snc/terraform-modules//athena_access_logs?ref=c8c77df64ea8ddf2937f1c79c8b0299158655090" # v4.9.10

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
  source            = "github.com/cds-snc/terraform-modules//S3?ref=bd904d01094f196fd3e8ff5c46e73838f1f1be26"
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

#
# Enable Athena Federated Query
#

resource "aws_s3_bucket" "athena_spill_bucket" {
  bucket = "gc-forms-${var.env}-athena-spill-bucket"
}

#
# Enables Amazon Athena to communicate with DynamoDB
#
resource "aws_serverlessapplicationrepository_cloudformation_stack" "dynamodb_connector" {
  name           = "dynamodb-connector"
  application_id = "arn:aws:serverlessrepo:us-east-1:292517598671:applications/AthenaDynamoDBConnector"
  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY",
  ]
  parameters = {
    AthenaCatalogName = "dynamodb-lambda-connector"
    SpillBucket       = aws_s3_bucket.athena_spill_bucket.id
  }
}

data "aws_lambda_function" "existing" {
  function_name = "dynamodb-lambda-connector"
  depends_on    = [aws_serverlessapplicationrepository_cloudformation_stack.dynamodb_connector]
}

resource "aws_athena_data_catalog" "dynamodb_data_catalog" {
  name        = "dynamodb-data-catalog"
  description = "Athena dynamodb data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = data.aws_lambda_function.existing.arn
  }
}