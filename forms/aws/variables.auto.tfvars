###
# Global
###

region = "ca-central-1"
# Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
billing_tag_key   = "CostCentre"
billing_tag_value = "Forms"
environment       = "staging"

###
# AWS Cloud Watch - cloudwatch.tf
###

cloudwatch_log_group_name = "Forms"

###
# AWS ECS - ecs.tf
###
list_manager_host    = "https://list-manager.alpha.canada.ca"
ircc_config          = "eyJmb3JtcyI6WzgxLDgzXSwibGFuZ3VhZ2VGaWVsZElEIjozLCJjb250YWN0RmllbGRJRCI6MiwibGlzdE1hcHBpbmciOnsiRW5nbGlzaCI6eyJwaG9uZSI6ImIxY2I3ZTFiLTIzZDktNDA0Yy05ZWY3LWI1NzY0MjIwNGEwMSIsImVtYWlsIjoiOGVlMDE1NDctMDVhYi00NzVjLTkzNGQtOGJmMmUzY2NiMDQ4In0sIkFuZ2xhaXMiOnsicGhvbmUiOiJiMWNiN2UxYi0yM2Q5LTQwNGMtOWVmNy1iNTc2NDIyMDRhMDEiLCJlbWFpbCI6IjhlZTAxNTQ3LTA1YWItNDc1Yy05MzRkLThiZjJlM2NjYjA0OCJ9LCJGcmVuY2giOnsicGhvbmUiOiI2OTYxYzFhMC1kODMzLTRmNWQtYjIyNC0xMzFkZDdkY2E2ZWQiLCJlbWFpbCI6IjdlZjU5NjZkLWRhODItNGI5MC1hMTk0LWJhMGMyNzI5MWRhOCJ9LCJGcmFuw6dhaXMiOnsicGhvbmUiOiI2OTYxYzFhMC1kODMzLTRmNWQtYjIyNC0xMzFkZDdkY2E2ZWQiLCJlbWFpbCI6IjdlZjU5NjZkLWRhODItNGI5MC1hMTk0LWJhMGMyNzI5MWRhOCJ9fX0="
ecs_name             = "Forms"
metric_provider      = "stdout"
tracer_provider      = "stdout"
ecs_form_viewer_name = "form-viewer"

#Autoscaling ECS

form_viewer_autoscale_enabled = true


###
# AWS RDS - rds.tf
###

rds_db_subnet_group_name = "forms-staging-db"

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

route53_zone_name = "forms-staging.cdssandbox.xyz"