#In this script, i first create a backup/snapshot of the current form db V1 database using the aws_rds_cluster_snapshot resource. 
#we then create a new V2 database using the aws_rds_cluster resource, specifying the engine, engine mode, and other configuration options.

#Next, we restore the backup to the V2 database using the aws_rds_cluster_instance_snapshot and aws_rds_cluster_instance resources. 
#We also update the application to use the new V2 database.

#Finally, we destroy the V1/old database using the aws_rds_cluster resource and setting 
#the skip_final_snapshot parameter to true, which will prevent a final snapshot from being created and save us from incurring additional charges.
# 

# Configure the AWS provider
provider "aws" {
  region = "ca-central-1"
}

# Create a backup of the V1 or form current database
resource "aws_rds_cluster_snapshot" "v1_db_backup" {
  db_cluster_identifier = "my-v1-cluster"
  db_cluster_snapshot_identifier = "my-v1-cluster-snapshot"
}

# Create a new V2 database
resource "aws_rds_cluster" "v2_db" {
  engine = "aurora-postgresql"
  engine_mode = "provisioned"
  engine_version = "10.14"
  database_name = "my-db"
  master_username           = var.rds_db_user
  master_password           = var.rds_db_password
  backup_retention_period = 7
  deletion_protection = true
  scaling_configuration {
    auto_pause = true
    max_capacity = 8
    min_capacity = 2
  }
}

# Restore the backup to the V2 database
resource "aws_rds_cluster_instance" "v2_db_instance" {
  count = 2
  identifier = "my-v2-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.v2_db.id
  instance_class = "db.t3.small"
}

resource "aws_rds_cluster_instance_snapshot" "v1_db_snapshot" {
  db_cluster_identifier = "my-v1-cluster"
  db_instance_identifier = "my-v1-instance"
  db_snapshot_identifier = "my-v1-instance-snapshot"
}

resource "aws_rds_cluster_instance" "v2_db_instance" {
  count = 2
  identifier = "my-v2-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.v2_db.id
  instance_class = "db.t3.small"
  db_cluster_snapshot_identifier = aws_rds_cluster_snapshot.v1_db_backup.id
}

# Update the form app to use the new V2 database
# ...

# Destroy the V1 database
resource "aws_rds_cluster" "v1_db" {
  count = 0
  db_cluster_identifier = "my-v1-cluster"
  skip_final_snapshot = true
}


# Current state

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
  cluster_identifier        = "${var.rds_name}-cluster"
  engine                    = "aurora-postgresql"
  engine_mode               = "provisioned"
  enable_http_endpoint      = true
  database_name             = var.rds_db_name
  deletion_protection       = true
  final_snapshot_identifier = "server-${random_string.random.result}"
  master_username           = var.rds_db_user
  master_password           = var.rds_db_password
  backup_retention_period   = 5
  preferred_backup_window   = "07:00-09:00"
  db_subnet_group_name      = aws_db_subnet_group.forms.name
  storage_encrypted         = true


  scaling_configuration {
    auto_pause   = false
    max_capacity = 8
    min_capacity = 2
  }

  vpc_security_group_ids = [var.rds_security_group_id]

  tags = {
    Name                  = "${var.rds_name}-cluster"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}
