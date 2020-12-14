###
# Global
###

region = "ca-central-1"
# Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
billing_tag_key   = "CostCentre"
billing_tag_value = "Forms"

###
# AWS Cloud Watch - cloudwatch.tf
###

cloudwatch_log_group_name = "Forms"

###
# AWS ECS - ecs.tf
###

ecs_name               = "Forms"
metric_provider        = "stdout"
tracer_provider        = "stdout"
ecs_form_viewer_name   = "form-viewer"
email_to               = "fitore.jaha.price@cds-snc.ca"
notify_endpoint        = "https://api.notification.canada.ca"
notify_template_id     = "2fc2653c-e19d-46bd-96c1-9c91a43d2ffe"
ssc_email_to           = "fitore.jaha.price@cds-snc.ca"
notify_ssc_template_id = "162d71e8-04c9-4966-8b71-6f14de2dbd42"

#Autoscaling ECS

form_viewer_autoscale_enabled = true

###
# AWS VPC - networking.tf
###

vpc_cidr_block = "172.16.0.0/16"
vpc_name       = "forms"


###
# AWS Route 53 - route53.tf
###

route53_zone_name = "forms-staging.cdssandbox.xyz"