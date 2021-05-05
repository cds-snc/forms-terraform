###
# Global
###

region = "ca-central-1"
# Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
billing_tag_key   = "CostCentre"
billing_tag_value = "Forms"
environment       = "sandbox"

###
# AWS Cloud Watch - cloudwatch.tf
###

cloudwatch_log_group_name = "Forms"

###
# AWS ECS - ecs.tf
###

ecs_name             = "Forms"
metric_provider      = "stdout"
tracer_provider      = "stdout"
ecs_form_viewer_name = "form-viewer"

#Autoscaling ECS

form_viewer_autoscale_enabled = true


###
# AWS RDS - rds.tf
###

rds_db_subnet_group_name = "forms-sandbox-db"

# RDS Cluster
rds_db_name = "forms"
rds_name    = "forms-staging-db"
rds_db_user = "postgres"
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# rds_db_password       = ""
rds_allocated_storage = "5"
rds_instance_class    = "db.t3.medium"


###
# AWS VPC - networking.tf
###

vpc_cidr_block = "172.16.0.0/16"
vpc_name       = "forms"


###
# AWS Route 53 - route53.tf
###

route53_zone_name = "forms-sandbox.cdssandbox.xyz"