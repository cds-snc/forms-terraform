# 
# ElastiCache (Redis)
# Stores Form app feature flags.
#
resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled = true
  replication_group_id       = "gcforms-redis-rep-group"
  description                = "Redis cluster for GCForms"
  node_type                  = "cache.t2.micro"
  num_cache_clusters         = 2
  engine_version             = "6.x"
  parameter_group_name       = "default.redis6.x"
  port                       = 6379
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.redis_security_group_id]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
