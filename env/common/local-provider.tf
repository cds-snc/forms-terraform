terraform {
  required_version = "1.3.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.75.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.3"
    }
  }
}

variable "localstack_host" {
  type    = string
  default = "localhost"
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "ca-central-1"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://${var.localstack_host}:4566"
    cloudformation = "http://${var.localstack_host}:4566"
    cloudwatch     = "http://${var.localstack_host}:4566"
    dynamodb       = "http://${var.localstack_host}:4566"
    ec2            = "http://${var.localstack_host}:4566"
    es             = "http://${var.localstack_host}:4566"
    elasticache    = "http://${var.localstack_host}:4566"
    firehose       = "http://${var.localstack_host}:4566"
    iam            = "http://${var.localstack_host}:4566"
    kinesis        = "http://${var.localstack_host}:4566"
    lambda         = "http://${var.localstack_host}:4566"
    rds            = "http://${var.localstack_host}:4566"
    redshift       = "http://${var.localstack_host}:4566"
    route53        = "http://${var.localstack_host}:4566"
    s3             = "http://${var.localstack_host}:4566"
    secretsmanager = "http://${var.localstack_host}:4566"
    ses            = "http://${var.localstack_host}:4566"
    sns            = "http://${var.localstack_host}:4566"
    sqs            = "http://${var.localstack_host}:4566"
    ssm            = "http://${var.localstack_host}:4566"
    stepfunctions  = "http://${var.localstack_host}:4566"
    sts            = "http://${var.localstack_host}:4566"
    kms            = "http://${var.localstack_host}:4566"
  }
}

provider "aws" {
  alias                       = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://${var.localstack_host}:4566"
    cloudformation = "http://${var.localstack_host}:4566"
    cloudwatch     = "http://${var.localstack_host}:4566"
    dynamodb       = "http://${var.localstack_host}:4566"
    ec2            = "http://${var.localstack_host}:4566"
    es             = "http://${var.localstack_host}:4566"
    elasticache    = "http://${var.localstack_host}:4566"
    firehose       = "http://${var.localstack_host}:4566"
    iam            = "http://${var.localstack_host}:4566"
    kinesis        = "http://${var.localstack_host}:4566"
    lambda         = "http://${var.localstack_host}:4566"
    rds            = "http://${var.localstack_host}:4566"
    redshift       = "http://${var.localstack_host}:4566"
    route53        = "http://${var.localstack_host}:4566"
    s3             = "http://${var.localstack_host}:4566"
    secretsmanager = "http://${var.localstack_host}:4566"
    ses            = "http://${var.localstack_host}:4566"
    sns            = "http://${var.localstack_host}:4566"
    sqs            = "http://${var.localstack_host}:4566"
    ssm            = "http://${var.localstack_host}:4566"
    stepfunctions  = "http://${var.localstack_host}:4566"
    sts            = "http://${var.localstack_host}:4566"
    kms            = "http://${var.localstack_host}:4566"
  }
}

provider "aws" {
  alias                       = "ca-central-1"
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "ca-central-1"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://${var.localstack_host}:4566"
    cloudformation = "http://${var.localstack_host}:4566"
    cloudwatch     = "http://${var.localstack_host}:4566"
    dynamodb       = "http://${var.localstack_host}:4566"
    ec2            = "http://${var.localstack_host}:4566"
    es             = "http://${var.localstack_host}:4566"
    elasticache    = "http://${var.localstack_host}:4566"
    firehose       = "http://${var.localstack_host}:4566"
    iam            = "http://${var.localstack_host}:4566"
    kinesis        = "http://${var.localstack_host}:4566"
    lambda         = "http://${var.localstack_host}:4566"
    rds            = "http://${var.localstack_host}:4566"
    redshift       = "http://${var.localstack_host}:4566"
    route53        = "http://${var.localstack_host}:4566"
    s3             = "http://${var.localstack_host}:4566"
    secretsmanager = "http://${var.localstack_host}:4566"
    ses            = "http://${var.localstack_host}:4566"
    sns            = "http://${var.localstack_host}:4566"
    sqs            = "http://${var.localstack_host}:4566"
    ssm            = "http://${var.localstack_host}:4566"
    stepfunctions  = "http://${var.localstack_host}:4566"
    sts            = "http://${var.localstack_host}:4566"
    kms            = "http://${var.localstack_host}:4566"
  }
}
