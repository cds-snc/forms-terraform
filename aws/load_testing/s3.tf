resource "aws_s3_bucket" "load_testing_lambda_package_dependencies" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket        = "${var.account_id}-load-testing-lambda-package-dependencies"
  force_destroy = true

  tags = var.core_tags
}

resource "aws_s3_bucket_public_access_block" "load_testing_lambda_package_dependencies" {
  bucket = aws_s3_bucket.load_testing_lambda_package_dependencies.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "load_testing_lambda_package_dependencies" {
  depends_on = [data.archive_file.load_testing_lambda_package_dependencies]

  bucket = aws_s3_bucket.load_testing_lambda_package_dependencies.id
  key    = "${data.archive_file.load_testing_lambda_package_dependencies.output_base64sha256}.zip"

  source      = data.archive_file.load_testing_lambda_package_dependencies.output_path
  source_hash = filemd5("${path.module}/lambda-code/requirements.txt")
}
