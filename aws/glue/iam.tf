#
# Glue crawler role
#
resource "aws_iam_role" "glue_crawler" {
  name               = "AWSGlueCrawler-DataLake"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

resource "aws_iam_policy" "glue_crawler" {
  name   = "AWSGlueCrawler-DataLake"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.glue_crawler_combined.json
}

data "aws_iam_policy_document" "glue_crawler_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_read_data_lake.json,
    data.aws_iam_policy_document.glue_kms.json
  ]
}

resource "aws_iam_role_policy_attachment" "glue_crawler" {
  policy_arn = aws_iam_policy.glue_crawler.arn
  role       = aws_iam_role.glue_crawler.name
}

resource "aws_iam_role_policy_attachment" "aws_glue_service_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_crawler.name
}

#
# Glue ETL role
#
resource "aws_iam_role" "glue_etl" {
  name               = "AWSGlueETL-DataLake"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

resource "aws_iam_policy" "glue_etl" {
  name   = "AWSGlueETL-DataLake"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.glue_etl_combined.json
}

data "aws_iam_policy_document" "glue_etl_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_read_data_lake.json,
    data.aws_iam_policy_document.s3_write_data_lake.json,
    data.aws_iam_policy_document.glue_kms.json
  ]
}

resource "aws_iam_role_policy_attachment" "glue_etl" {
  policy_arn = aws_iam_policy.glue_etl.arn
  role       = aws_iam_role.glue_etl.name
}

resource "aws_iam_role_policy_attachment" "glue_etl_service_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_etl.name
}

#
# Custom policies
#
data "aws_iam_policy_document" "glue_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "glue.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_read_data_lake" {
  statement {
    sid = "ReadDataLakeS3Buckets"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${var.datalake_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "glue_kms" {
  statement {
    sid    = "UseGlueKey"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:RetireGrant"
    ]
    resources = [
      aws_kms_key.aws_glue.arn
    ]
  }

  statement {
    sid    = "AssociateKmsKey"
    effect = "Allow"
    actions = [
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws-glue/crawlers*",
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws-glue/jobs*",
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws-glue/sessions*"
    ]
  }
}

data "aws_iam_policy_document" "s3_write_data_lake" {
  statement {
    sid = "WriteDataLakeS3TransformedBuckets"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${var.datalake_bucket_arn}/*"
    ]
  }
}