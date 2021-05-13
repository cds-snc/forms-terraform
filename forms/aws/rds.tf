resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_db_subnet_group" "forms" {
  name       = var.rds_db_subnet_group_name
  subnet_ids = aws_subnet.forms_private.*.id

  tags = {
    Name                  = var.rds_db_subnet_group_name
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_rds_cluster" "forms" {
  cluster_identifier        = "${var.rds_name}-cluster"
  engine                    = "aurora-postgresql"
  engine_mode               = "serverless"
  enable_http_endpoint      = true
  database_name             = var.rds_db_name
  final_snapshot_identifier = "server-${random_string.random.result}"
  master_username           = var.rds_db_user
  master_password           = var.rds_db_password
  backup_retention_period   = 5
  preferred_backup_window   = "07:00-09:00"
  db_subnet_group_name      = aws_db_subnet_group.forms.name
  storage_encrypted         = true
  #tfsec:ignore:AWS051
  # KMS key is not explicitly defined but a default key is created

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 8
    min_capacity             = 2
    seconds_until_auto_pause = 300
  }


  vpc_security_group_ids = [
    aws_security_group.forms_database.id
  ]

  tags = {
    Name                  = "${var.rds_name}-cluster"
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}