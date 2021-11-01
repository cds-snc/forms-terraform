
terraform {
  required_version = "= 1.0.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.63.0"
    }
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
}
