terraform {
  source = "../../../aws//secrets"
}

include {
  path = find_in_parent_folders()
}

locals {
  env                                = get_env("APP_ENV", "local")
  ecs_secret_token                   = get_env("ECS_SECRET_TOKEN", "I_am_not_a_secret_token")
  recaptcha_secret                   = get_env("RECAPTCHA_SECRET", "I_am_not_a_secret_token")
  notify_callback_bearer_token       = get_env("NOTIFY_CALLBACK_BEARER_TOKEN", "I_am_not_a_secret_token")
  notify_api_key                     = get_env("NOTIFY_API_KEY", "I_am_not_a_secret_token")
  freshdesk_api_key                  = get_env("FRESHDESK_API_KEY", "I_am_not_a_secret_token")
  sentry_api_key                     = get_env("SENTRY_API_KEY", "I_am_not_a_secret_token")
  next_server_actions_encryption_key = get_env("NEXT_SERVER_ACTIONS_ENCRYPTION_KEY", "I_am_not_a_secret_token")
  zitadel_administration_key         = get_env("ZITADEL_ADMINISTRATION_KEY", "I_am_not_a_secret_token")
  zitadel_application_key            = get_env("ZITADEL_APPLICATION_KEY", "I_am_not_a_secret_token")
  rds_db_password                    = "chummy"
}

inputs = {
  ecs_secret_token             = local.ecs_secret_token
  recaptcha_secret             = local.recaptcha_secret
  notify_callback_bearer_token = local.notify_callback_bearer_token
  notify_api_key               = local.notify_api_key
  freshdesk_api_key            = local.freshdesk_api_key
  zitadel_administration_key   = local.zitadel_administration_key
  zitadel_application_key      = local.zitadel_application_key
  # Overwritten in GitHub Actions by TFVARS
  rds_db_password                    = local.rds_db_password
  sentry_api_key                     = local.sentry_api_key
  next_server_actions_encryption_key = local.next_server_actions_encryption_key
}