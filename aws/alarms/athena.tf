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
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  bucket = "gc-forms-${var.env}-athena-spill-bucket"
}

resource "aws_s3_bucket_public_access_block" "athena_spill_bucket" {
  bucket                  = aws_s3_bucket.athena_spill_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_spill_bucket" {
  # checkov:skip=CKV_AWS_300: Lifecycle configuration for aborting failed (multipart) upload not required
  bucket = aws_s3_bucket.athena_spill_bucket.id

  rule {
    id     = "Clear spill bucket after 1 day"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
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
    LambdaRole        = aws_iam_role.athena_dynamodb_role.arn
  }
}

data "aws_lambda_function" "existing" {
  function_name = "dynamodb-lambda-connector"
  depends_on    = [aws_serverlessapplicationrepository_cloudformation_stack.dynamodb_connector]
}

resource "aws_athena_data_catalog" "dynamodb" {
  name        = "dynamodb"
  description = "Athena dynamodb data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = data.aws_lambda_function.existing.arn
  }
}

resource "aws_iam_role_policy" "athena_dynamodb_policy" {
  name = "athena_dynamodb_policy"
  role = aws_iam_role.athena_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      },
      {
        "Action" : [
          "glue:GetTableVersions",
          "glue:GetPartitions",
          "glue:GetTables",
          "glue:GetTableVersion",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetPartition",
          "glue:GetDatabase",
          "athena:GetQueryExecution",
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:ListSchemas",
          "dynamodb:ListTables",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PartiQLSelect"
        ],
        "Resource" : "${var.dynamodb_audit_logs_arn}",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : "${var.kms_key_dynamodb_arn}",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.athena_spill_bucket.arn}",
          "${aws_s3_bucket.athena_spill_bucket.arn}/*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "athena_dynamodb_role" {
  name = "athena_dynamodb_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}