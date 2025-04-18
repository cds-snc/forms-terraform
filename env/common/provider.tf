terraform {
  required_version = "1.11.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
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
