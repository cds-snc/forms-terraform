terraform {
  source = "../../../aws//secrets"
}

inputs = {
ecs_secret_token = "I_am_not_a_secret_token"
recaptcha_secret = "I_am_not_a_secret_token"
gc_notify_callback_bearer_token = "I_am_not_a_secret_token"
notify_api_key = get_env("NOTIFY_API_KEY", "I_am_not_a_secret_token")
freshdesk_api_key = "I_am_not_a_secret_token"
}

include {
  path = find_in_parent_folders()
}

