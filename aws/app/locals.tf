locals {
  # Lower the ECS task count for non-production environments
  ecs_max_tasks = var.env == "production" ? var.ecs_max_tasks : 2
  ecs_min_tasks = var.env == "production" ? var.ecs_min_tasks : 1
}
