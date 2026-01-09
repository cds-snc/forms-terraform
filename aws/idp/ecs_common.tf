#
# ECS Cluster
# Fargate cluster that runs the IDP and User Portal
#
resource "aws_ecs_cluster" "idp" {
  name = "idp"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
