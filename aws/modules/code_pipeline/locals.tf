locals {
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecs_task_definition" "this" {
  task_definition = var.task_definition_family
}
data "aws_lb_target_group" "this" {
  name = var.loadblancer_target_group_names[0]
}