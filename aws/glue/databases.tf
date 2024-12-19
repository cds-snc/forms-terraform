resource "aws_glue_catalog_database" "rds_db_catalog" {
  name        = "rds_db_catalog"
  description = "Source : RDS"
}