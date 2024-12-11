locals {
  forms_api_release                   = "forms-api-release"
  platform_forms_client_pr_review_env = "platform-forms-client-pr-review-env"
  platform_forms_client_release       = "platform-forms-client-release"
}

# 
# Built-in AWS policy attached to the roles
#
data "aws_iam_policy" "admin" {
  # checkov:skip=CKV_AWS_275:This policy is required for the Terraform apply
  name = "AdministratorAccess"
}

#
# Create the OIDC roles used by the GitHub workflows
# The roles can be assumed by the GitHub workflows according to the `claim`
# attribute of each role.
# 
module "github_workflow_roles" {
  source            = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=64b19ecfc23025718cd687e24b7115777fd09666" # v10.2.1
  billing_tag_value = var.billing_tag_value
  roles = [
    {
      name      = local.forms_api_release
      repo_name = "forms-api"
      claim     = "ref:refs/tags/v*"
    },
    {
      name      = local.platform_forms_client_pr_review_env
      repo_name = "platform-forms-client"
      claim     = "pull_request"
    },
    {
      name      = local.platform_forms_client_release
      repo_name = "platform-forms-client"
      claim     = "ref:refs/tags/v*"
    }
  ]
}

#
# Attach polices to the OIDC roles to grant them permissions.  These
# attachments are scoped to only the environments that require the role.
#
resource "aws_iam_role_policy_attachment" "forms_api_release" {
  count      = var.env == "production" ? 1 : 0
  role       = local.forms_api_release
  policy_arn = aws_iam_policy.forms_api_release[0].arn
  depends_on = [
    module.github_workflow_roles
  ]
}

resource "aws_iam_role_policy_attachment" "platform_forms_client_pr_review_env" {
  count      = var.env == "staging" ? 1 : 0
  role       = local.platform_forms_client_pr_review_env
  policy_arn = aws_iam_policy.platform_forms_client_pr_review_env[0].arn
  depends_on = [
    module.github_workflow_roles
  ]
}

resource "aws_iam_role_policy_attachment" "platform_forms_client_release" {
  count      = var.env == "production" ? 1 : 0
  role       = local.platform_forms_client_release
  policy_arn = aws_iam_policy.platform_forms_client_release[0].arn
  depends_on = [
    module.github_workflow_roles
  ]
}
