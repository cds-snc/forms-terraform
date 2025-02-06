locals {
  glue_crawler_log_group_name = "/aws-glue/crawlers-role${aws_iam_role.glue_crawler.path}${aws_iam_role.glue_crawler.name}-${aws_glue_security_configuration.encryption_at_rest.name}"
  glue_etl_log_group_name     = "/aws-glue/jobs/${aws_glue_security_configuration.encryption_at_rest.name}-role${aws_iam_role.glue_crawler.path}${aws_iam_role.glue_etl.name}"
}