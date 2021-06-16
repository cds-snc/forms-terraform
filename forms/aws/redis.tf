resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled    = true
  replication_group_id          = "gcforms-redis-rep-group"
  replication_group_description = "Redis cluster for GCForms"
  node_type                     = "cache.t2.micro"
  number_cache_clusters         = 2
  engine_version                = "6.x"
  parameter_group_name          = "default.redis6.x"
  port                          = 6379
  multi_az_enabled              = true
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.forms_redis.id]

}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = aws_subnet.forms_private.*.id
}