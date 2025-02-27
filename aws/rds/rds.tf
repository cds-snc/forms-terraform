locals {
  rds_engine         = "aurora-postgresql"
  rds_engine_version = var.env == "development" ? "16.4" : "13.12"
}

resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_db_subnet_group" "forms" {
  name       = var.rds_db_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name                  = var.rds_db_subnet_group_name
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_rds_cluster" "forms" {
  # checkov:skip=CKV_AWS_324: RDS Cluster log capture not required
  # checkov:skip=CKV_AWS_327: Encryption using KMS CMKs not required
  // TODO: Implement Encryption using KMS CMKs

  cluster_identifier          = "${var.rds_name}-cluster"
  engine                      = local.rds_engine
  engine_version              = local.rds_engine_version
  enable_http_endpoint        = true
  database_name               = var.rds_db_name
  deletion_protection         = var.env  != "development"
  final_snapshot_identifier   = "server-${random_string.random.result}"
  master_username             = var.rds_db_user
  master_password             = var.rds_db_password
  backup_retention_period     = 5
  preferred_backup_window     = "07:00-09:00"
  db_subnet_group_name        = aws_db_subnet_group.forms.name
  storage_encrypted           = true
  allow_major_version_upgrade = true
  copy_tags_to_snapshot       = true
  apply_immediately           = var.env == "development"

  serverlessv2_scaling_configuration {
    max_capacity = var.env == "development" ? 4 : 8
    min_capacity = var.env == "development" ? 0 : 2
    # Pause DB after 15 minutes of inactivity in development environment
    seconds_until_auto_pause = var.env == "development" ? 900 : null
  }

  vpc_security_group_ids = [var.rds_security_group_id]

  tags = {
    Name = "${var.rds_name}-cluster"
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}

resource "aws_rds_cluster_instance" "forms" {
  #checkov:skip=CKV_AWS_118:enhanced monitoring is not required
  #checkov:skip=CKV_AWS_353:performance insights are not required
  #checkov:skip=CKV_AWS_354:performance insights are not required 

  identifier                 = "${var.rds_name}-cluster-instance-2"
  cluster_identifier         = aws_rds_cluster.forms.id
  instance_class             = "db.serverless"
  engine                     = local.rds_engine
  engine_version             = local.rds_engine_version
  db_subnet_group_name       = aws_db_subnet_group.forms.name
  auto_minor_version_upgrade = true
  promotion_tier             = 1
  apply_immediately          = var.env == "development"
}