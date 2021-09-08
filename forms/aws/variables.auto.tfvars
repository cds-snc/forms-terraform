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
ircc_config          = "eyJmb3JtcyI6WzgxLDgzXSwicHJvZ3JhbUZpZWxkSUQiOjIsImxhbmd1YWdlRmllbGRJRCI6NCwiY29udGFjdEZpZWxkSUQiOjMsImxpc3RNYXBwaW5nIjp7IkVuZ2xpc2giOnsiSW1taWdyYXRpb24gcHJvZ3JhbSBmb3IgQWZnaGFucyB3aG8gYXNzaXN0ZWQgdGhlIEdvdmVybm1lbnQgb2YgQ2FuYWRhIGFuZCB0aGVpciBlbGlnaWJsZSBmYW1pbHkgbWVtYmVycy4iOnsicGhvbmUiOiJiYWNjYmE4Mi02MDg3LTQ2OTctOGU5MS1lZmUwNmU3MzU3MmUiLCJlbWFpbCI6ImJhZTFjYjU4LTg3OTItNDQ5Mi1iMzVjLWIxNTk1YTE2MWFlMiJ9LCJIdW1hbml0YXJpYW4gcHJvZ3JhbSB0byBoZWxwIEFmZ2hhbiBuYXRpb25hbHMgcmVzZXR0bGUgdG8gQ2FuYWRhLiI6eyJwaG9uZSI6IjI4ZmVjMjgzLWIyNWItNDdjMS05OWVlLWU0OGMyMDhlZmEyMyIsImVtYWlsIjoiYWIyNmE2YjUtNTdhYS00Y2MyLTg1ZmUtMzA1M2VkMzQ0ZmU4In19LCJBbmdsYWlzIjp7IlByb2dyYW1tZSBk4oCZaW1taWdyYXRpb24gcG91ciBsZXMgQWZnaGFucyBxdWkgb250IGFpZMOpIGxlIGdvdXZlcm5lbWVudCBkdSBDYW5hZGEgZXQgbGVzIG1lbWJyZXMgYWRtaXNzaWJsZXMgZGUgbGV1cnMgZmFtaWxsZXMuIjp7InBob25lIjoiYmFjY2JhODItNjA4Ny00Njk3LThlOTEtZWZlMDZlNzM1NzJlIiwiZW1haWwiOiJiYWUxY2I1OC04NzkyLTQ0OTItYjM1Yy1iMTU5NWExNjFhZTIifSwiUHJvZ3JhbW1lIGh1bWFuaXRhaXJlIHBvdXIgYWlkZXIgbGVzIGFmZ2hhbnMgw6Agc+KAmWluc3RhbGxlciBhdSBDYW5hZGEuIjp7InBob25lIjoiMjhmZWMyODMtYjI1Yi00N2MxLTk5ZWUtZTQ4YzIwOGVmYTIzIiwiZW1haWwiOiJhYjI2YTZiNS01N2FhLTRjYzItODVmZS0zMDUzZWQzNDRmZTgifX0sIkZyZW5jaCI6eyJJbW1pZ3JhdGlvbiBwcm9ncmFtIGZvciBBZmdoYW5zIHdobyBhc3Npc3RlZCB0aGUgR292ZXJubWVudCBvZiBDYW5hZGEgYW5kIHRoZWlyIGVsaWdpYmxlIGZhbWlseSBtZW1iZXJzLiI6eyJwaG9uZSI6IjUzMzQyNGM2LTUxMzAtNDMzMS1hNGZhLTQyYjBjNjliNmUxMSIsImVtYWlsIjoiY2RmN2QzNzAtNzFjMi00OGFkLTlkNTktNGUyZjdiOWI4MjhhIn0sIkh1bWFuaXRhcmlhbiBwcm9ncmFtIHRvIGhlbHAgQWZnaGFuIG5hdGlvbmFscyByZXNldHRsZSB0byBDYW5hZGEuIjp7InBob25lIjoiNDQ5M2JlOTEtNGVlMi00MmNjLTg3ZDYtOWU0ZWI4YTA4NTU0IiwiZW1haWwiOiJlYmE3OWVkYS0wY2I2LTRmZjYtYmUwMy1hNmZkZTE1NjVkOTYifX0sIkZyYW7Dp2FpcyI6eyJQcm9ncmFtbWUgZOKAmWltbWlncmF0aW9uIHBvdXIgbGVzIEFmZ2hhbnMgcXVpIG9udCBhaWTDqSBsZSBnb3V2ZXJuZW1lbnQgZHUgQ2FuYWRhIGV0IGxlcyBtZW1icmVzIGFkbWlzc2libGVzIGRlIGxldXJzIGZhbWlsbGVzLiI6eyJwaG9uZSI6IjUzMzQyNGM2LTUxMzAtNDMzMS1hNGZhLTQyYjBjNjliNmUxMSIsImVtYWlsIjoiY2RmN2QzNzAtNzFjMi00OGFkLTlkNTktNGUyZjdiOWI4MjhhIn0sIlByb2dyYW1tZSBodW1hbml0YWlyZSBwb3VyIGFpZGVyIGxlcyBhZmdoYW5zIMOgIHPigJlpbnN0YWxsZXIgYXUgQ2FuYWRhLiI6eyJwaG9uZSI6IjQ0OTNiZTkxLTRlZTItNDJjYy04N2Q2LTllNGViOGEwODU1NCIsImVtYWlsIjoiZWJhNzllZGEtMGNiNi00ZmY2LWJlMDMtYTZmZGUxNTY1ZDk2In19fX0K"
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