terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.63.0"
    }
  }
  required_version = "= 1.0.10"
}

provider "aws" {
  region = "ca-central-1"
}

variable "tfstate_bucket_name" {
  description = "Name of the S3 bucket to use to store the tfstate"
  type        = string
}

module "state_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v0.0.38//S3"
  bucket_name       = var.tfstate_bucket_name
  billing_tag_value = "Forms"

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.state_bucket_logs.s3_bucket_id
  }
}

module "state_bucket_logs" {
  source            = "github.com/cds-snc/terraform-modules?ref=v0.0.38//S3_log_bucket"
  bucket_name       = "${var.tfstate_bucket_name}-log"
  force_destroy     = true
  billing_tag_value = "Forms"
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name           = "tfstate-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
