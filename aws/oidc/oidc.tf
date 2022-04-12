locals {
  plan_name  = "gh_plan_role"
  admin_name = "gh_admin_role"
}


module "oidc" {
  source            = "github.com/cds-snc/terraform-modules?ref=v2.0.1//gh_oidc_role"
  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
  roles = [
    {
      name : local.admin_name,
      repo_name : "forms-terraform"
      claim : "ref:refs/heads/main"
    },
    {
      name : local.plan_name,
      repo_name : "forms-terraform"
      claim : "*"
    }
  ]

}


## Policy required for running TF Plans ReadOnly is needed along with some other policies.
data "aws_iam_policy" "readonly" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = local.plan_name
  policy_arn = data.aws_iam_policy.readonly.arn
}

## Gives the plan role access to all secrets in the repo this is needed since ReadOnly doesn't provide that access
## This also gives the plan role the ability to the state bucket and the dynamodb lock table.
module "attach_tf_plan_policy" {
  source     = "github.com/cds-snc/terraform-modules?ref=v2.0.1//attach_tf_plan_policy"
  account_id = var.account_id
  role_name  = local.plan_name
  # This needs to match the data in the root terragrunt.hcl
  bucket_name       = "forms-terraform-{var.env}-tf"
  lock_table_name   = "tfstate-lock"
  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = local.admin_name
  policy_arn = data.aws_iam_policy.admin.arn
}