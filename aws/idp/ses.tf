#
# Send email using a SES SMTP server
#
resource "aws_ses_domain_identity" "idp" {
  domain = local.ipd_domains[0]
}

resource "aws_ses_domain_dkim" "idp" {
  domain = aws_ses_domain_identity.idp.domain
}

resource "aws_ses_domain_identity_verification" "idp" {
  domain     = aws_ses_domain_identity.idp.id
  depends_on = [aws_route53_record.idp_ses_verification_TXT]
}

resource "aws_iam_user" "idp_send_email" {
  # checkov:skip=CKV_AWS_273: SES IAM user is required to confirgure SMTP credentials
  name = "idp_send_email"
}

resource "aws_iam_group" "idp_send_email" {
  name = "idp_send_email"
}

resource "aws_iam_group_membership" "idp_send_email" {
  name  = aws_iam_user.idp_send_email.name
  group = aws_iam_group.idp_send_email.name
  users = [
    aws_iam_user.idp_send_email.name
  ]
}

resource "aws_iam_group_policy_attachment" "idp_send_email" {
  group      = aws_iam_user.idp_send_email.name
  policy_arn = aws_iam_policy.idp_send_email.arn
}

data "aws_iam_policy_document" "idp_send_email" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail"
    ]
    resources = [
      aws_ses_domain_identity.idp.arn
    ]
  }
}

resource "aws_iam_policy" "idp_send_email" {
  name   = "idp_send_email"
  policy = data.aws_iam_policy_document.idp_send_email.json
}

resource "aws_iam_access_key" "idp_send_email" {
  user = aws_iam_user.idp_send_email.name
}
