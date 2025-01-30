# Glue jobs
resource "aws_security_group" "glue_job" {
  description = "AWS Glue jobs"
  name        = "glue_job"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "glue_job_egress_internet" {
  description       = "Egress from Glue jobs to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.glue_job.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "forms_db_ingress_glue_job" {
  description              = "Ingress to Forms database from Glue jobs"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_database.id
  source_security_group_id = aws_security_group.glue_job.id
}

resource "aws_security_group_rule" "glue_job_egress_forms_db" {
  description              = "Egress from Glue jobs to Forms database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_job.id
  source_security_group_id = aws_security_group.forms_database.id
}

resource "aws_security_group_rule" "glue_job_egress_privatelink" {
  description              = "Egress from AWS Glue jobs to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_job.id
  source_security_group_id = aws_security_group.privatelink.id
}
