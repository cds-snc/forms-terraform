terraform {
  required_version = "1.9.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.6.0"
    }
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
  default_tags {
    tags = {
      (var.billing_tag_key) = var.billing_tag_value
      Terraform             = true
    }
  }
}

provider "aws" {
  alias               = "us-east-1"
  region              = "us-east-1"
  allowed_account_ids = [var.account_id]
  default_tags {
    tags = {
      (var.billing_tag_key) = var.billing_tag_value
      Terraform             = true
    }
  }
}
