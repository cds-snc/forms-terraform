# 
# ElastiCache (Redis)
# Stores Form app feature flags.
#

resource "aws_elasticache_replication_group" "redis" {
  # checkov:skip=CKV_AWS_191: KMS encryption using customer managed key not required
  automatic_failover_enabled = var.env == "local" ? false : true
  replication_group_id       = "gcforms-redis-rep-group"
  description                = "Redis cluster for GCForms"
  node_type                  = "cache.t2.micro"
  num_cache_clusters         = var.env == "local" ? 1 : 2         # In Localstack, if Elasticache is used to host a Redis service it cannot have more than one node
  engine_version             = var.env == "local" ? "6.2" : "6.x" # Localstack does not accept the use of latest minor version (`.x`) at creation time
  parameter_group_name       = "default.redis6.x"
  port                       = 6379
  multi_az_enabled           = var.env == "local" ? false : true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.redis_security_group_id]
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}