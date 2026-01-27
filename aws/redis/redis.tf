# 
# ElastiCache (Redis)
# Stores Form app feature flags.
#

resource "aws_elasticache_replication_group" "redis" {
  # checkov:skip=CKV_AWS_191: KMS encryption using customer managed key not required
  # checkov:skip=CKV2_AWS_50: Multi AZ is enabled in staging and production
  automatic_failover_enabled = var.env != "development"
  replication_group_id       = "gcforms-redis-rep-group"
  description                = "Redis cluster for GCForms"
  node_type                  = "cache.t2.micro"
  num_cache_clusters         = var.env == "development" ? 1 : 2
  engine_version             = "7.x"
  parameter_group_name       = "default.redis6.x"
  port                       = 6379
  multi_az_enabled           = var.env != "development"
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.redis_security_group_id]
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}