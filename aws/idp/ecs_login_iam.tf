#
# IAM - IDP User Portal ECS task role
#
resource "aws_iam_role" "idp_user_portal" {
  name               = "idp_user_portal"
  assume_role_policy = data.aws_iam_policy_document.idp_user_portal.json
}

data "aws_iam_policy_document" "idp_user_portal" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#
# IAM policies
#

resource "aws_iam_policy" "user_portal_ssm" {
  name   = "formsS3Access"
  path   = "/"
  policy = data.aws_iam_policy_document.idp_login_task_ssm_parameters.json
}

data "aws_iam_policy_document" "idp_login_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.idp_login_service_user_token.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_xray" {
  name        = "ecs_xray"
  path        = "/"
  description = "IAM policy for allowing X-Ray tracing"
  policy      = data.aws_iam_policy_document.ecs_xray.json
}

data "aws_iam_policy_document" "ecs_xray" {
  # checkov:skip=CKV_AWS_111: IAM policy recommended by AWS
  # checkov:skip=CKV_AWS_356: IAM policy recommended by AWS
  # checkov:skip=CKV_AWS_108: IAM policy recommended by AWS
  statement {
    effect = "Allow"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
      "ssm:GetParameters"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_forms" {
  role       = aws_iam_role.idp_user_portal.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_user_portal" {
  role       = aws_iam_role.idp_user_portal.name
  policy_arn = aws_iam_policy.user_portal_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ecs_xray" {
  role       = aws_iam_role.idp_user_portal.name
  policy_arn = aws_iam_policy.ecs_xray.arn
}


#
# IAM - Codedeploy
#
resource "aws_iam_role" "codedeploy" {
  name               = "codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_codedeploy.json
  path               = "/"
}

data "aws_iam_policy_document" "assume_role_policy_codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

