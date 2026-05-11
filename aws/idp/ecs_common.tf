#
# ECS Cluster
# Fargate cluster that runs the GC Forms IDP
# Note: this cluster exist because we used to run an SSO user portal in it
#
resource "aws_ecs_cluster" "idp" {
  name = "auth"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
