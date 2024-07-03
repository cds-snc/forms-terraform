#
# Send email using a SES SMTP server
#
resource "aws_ses_domain_identity" "idp" {
  domain = var.domain_idp
}

resource "aws_ses_domain_identity_verification" "idp" {
  domain     = aws_ses_domain_identity.idp.id
  depends_on = [aws_route53_record.idp_ses_verification_TXT]
}

resource "aws_iam_user" "idp_send_email" {
  name = "idp_send_email"
}

data "aws_iam_policy_document" "idp_send_email" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "idp_send_email" {
  name   = "idp_send_email"
  policy = data.aws_iam_policy_document.idp_send_email.json
}

resource "aws_iam_user_policy_attachment" "idp_send_email" {
  user       = aws_iam_user.idp_send_email.name
  policy_arn = aws_iam_policy.idp_send_email.arn
}

resource "aws_iam_access_key" "idp_send_email" {
  user = aws_iam_user.idp_send_email.name
}
