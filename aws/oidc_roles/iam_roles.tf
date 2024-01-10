locals {
  forms_terraform_apply_release           = "forms-terraform-apply-release"
  forms_terraform_apply_workflow_dispatch = "forms-terraform-apply-workflow-dispatch"
  forms_terraform_plan_workflow_dispatch  = "forms-terraform-plan-workflow-dispatch"
  platform_forms_client_pr_review_env     = "platform-forms-client-pr-review-env"
  platform_forms_client_release           = "platform-forms-client-release"
}

# 
# Built-in AWS polices attached to the roles
#
data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

data "aws_iam_policy" "readonly" {
  name = "ReadOnlyAccess"
}

#
# Custom OIDC policy managed by the SRE team.  It is created and managed by
# cds-snc/aft-global-customizations/terraform/oidc_terraform_roles.tf
#
data "aws_iam_policy" "terraform_plan" {
  name = "OIDCPlanPolicy"
}

#
# Create the OIDC roles used by the GitHub workflows
# The roles can be assumed by the GitHub workflows according to the `claim`
# attribute of each role, which corresponds to the GitHub workflow's event_name.
# 
module "github_workflow_roles" {
  source            = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v9.0.0"
  billing_tag_value = var.billing_tag_value
  roles = [
    {
      name      = local.forms_terraform_apply_release
      repo_name = "forms-terraform"
      claim     = "release"
    },
    {
      name      = local.forms_terraform_apply_workflow_dispatch
      repo_name = "forms-terraform"
      claim     = "workflow_dispatch"
    },
    {
      name      = local.forms_terraform_plan_workflow_dispatch
      repo_name = "forms-terraform"
      claim     = "workflow_dispatch"
    },
    {
      name      = local.platform_forms_client_pr_review_env
      repo_name = "platform-forms-client"
      claim     = "pull_request"
    },
    {
      name      = local.platform_forms_client_release
      repo_name = "platform-forms-client"
      claim     = "release"
    }
  ]
}

#
# Attach polices to the OIDC roles to grant them permissions.  These
# attachments are scoped to only the environments that require the role.
#
resource "aws_iam_role_policy_attachment" "forms_terraform_apply_release_admin" {
  count      = var.env == "production" ? 1 : 0
  role       = local.forms_terraform_apply_release
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.github_workflow_roles
  ]
}

resource "aws_iam_role_policy_attachment" "forms_terraform_apply_workflow_dispatch_admin" {
  count      = var.env == "staging" ? 1 : 0
  role       = local.forms_terraform_apply_workflow_dispatch
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.github_workflow_roles
  ]
}

resource "aws_iam_role_policy_attachment" "forms_terraform_plan_workflow_dispatch_terraform_plan" {
  count      = var.env == "staging" ? 1 : 0
  role       = local.forms_terraform_plan_workflow_dispatch
  policy_arn = data.aws_iam_policy.terraform_plan.arn
  depends_on = [
    module.github_workflow_roles
  ]
}

resource "aws_iam_role_policy_attachment" "forms_terraform_plan_workflow_dispatch_readonly" {
  count      = var.env == "staging" ? 1 : 0
  role       = local.forms_terraform_plan_workflow_dispatch
  policy_arn = data.aws_iam_policy.readonly.arn
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
