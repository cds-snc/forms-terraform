
variable "ecs_secret_token" {
  description = "Forms ECS JSON Web Token (JWT) secret used by Templates lambda"
  type        = string
  sensitive   = true
}

variable "recaptcha_secret" {
  description = "Secret Site Key for reCAPTCHA"
  type        = string
  sensitive   = true
}

variable "notify_callback_bearer_token" {
  description = "GC Notify callback bearer token which will be used as an authentication factor in GC Forms"
  type        = string
  sensitive   = true
}

variable "notify_api_key" {
  description = "The Notify API key used by the ECS task and Lambda"
  type        = string
  sensitive   = true
}

variable "freshdesk_api_key" {
  description = "The FreshDesk API key used by the ECS task and Lambda"
  type        = string
  sensitive   = true
}

variable "sentry_api_key" {
  description = "The Sentry API key used by the ECS task and Lambda"
  type        = string
  sensitive   = true
}

variable "zitadel_administration_key" {
  description = "The Zitadel administration key used by the ECS task and Lambda"
  type        = string
  sensitive   = true
}

variable "zitadel_application_key" {
  description = "The Zitadel application key used by the ECS task (API)"
  type        = string
  sensitive   = true
}

variable "hcaptcha_site_verify_key" {
  description = "The hCaptcha site verify key secret used for forms"
  type        = string
  sensitive   = true
}
