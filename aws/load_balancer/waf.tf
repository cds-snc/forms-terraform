#
# WAF
# Defines the firewall rules protecting the ALB
#

locals {
  # AWSManagedRulesCommonRuleSet to exclude.
  excluded_rules_common                  = ["GenericRFI_QUERYARGUMENTS", "GenericRFI_BODY", "SizeRestrictions_BODY"]
  cognito_login_outside_canada_rule_name = "AWSCognitoLoginOutsideCanada"
}

resource "aws_wafv2_rule_group" "rate_limiters_group" {
  capacity = 32 // 2, as a base cost. For each custom aggregation key that you specify, add 30 WCUs.
  name     = "RateLimitersGroup"
  scope    = "REGIONAL"

  rule {
    name     = "BlanketRequestLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2500
        aggregate_key_type = "IP"
        scope_down_statement {
          not_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                field_to_match {
                  single_header {
                    name = "host"
                  }
                }
                search_string = var.domain_api
                text_transformation {
                  priority = 1
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlanketRequestLimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "PostRequestLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
        scope_down_statement {
          and_statement {
            statement {
              not_statement {
                statement {
                  byte_match_statement {
                    positional_constraint = "EXACTLY"
                    field_to_match {
                      single_header {
                        name = "host"
                      }
                    }
                    search_string = var.domain_api
                    text_transformation {
                      priority = 1
                      type     = "LOWERCASE"
                    }
                  }
                }
              }
            }
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                field_to_match {
                  method {}
                }
                search_string = "post"
                text_transformation {
                  priority = 1
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PostRequestRateLimit"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitersGroup"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl" "forms_acl" {
  name  = "GCForms"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitersRuleGroup"
    priority = 10

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.rate_limiters_group.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate_limiters_rule_group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "PreventHostInjections"
    priority = 20

    statement {
      not_statement {
        statement {
          regex_pattern_set_reference_statement {

            arn = aws_wafv2_regex_pattern_set.forms_base_url.arn

            field_to_match {
              single_header {
                name = "host"
              }
            }

            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PreventHostInjections"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = local.excluded_rules_common
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 40
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "forms_global_rule"
    sampled_requests_enabled   = false
  }

  rule {
    name     = "AllowOnlyAppUrls"
    priority = 60

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.valid_app_uri_paths.arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "COMPRESS_WHITE_SPACE"
            }
            text_transformation {
              priority = 2
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowOnlyAppUrls"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = local.cognito_login_outside_canada_rule_name
    priority = 70

    action {
      count {}
    }

    statement {
      and_statement {
        statement {
          not_statement {
            statement {
              geo_match_statement {
                country_codes = ["CA"]
              }
            }
          }
        }

        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.cognito_login_paths.arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "COMPRESS_WHITE_SPACE"
            }
            text_transformation {
              priority = 2
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      metric_name                = local.cognito_login_outside_canada_rule_name
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "BlockedIPv4"
    priority = 80

    action {
      count {}
    }

    statement {
      ip_set_reference_statement {
        arn = module.waf_ip_blocklist.ipv4_blocklist_arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockedIPv4"
      sampled_requests_enabled   = true
    }
  }
}

// Matches the login paths for cognito /api/auth/signin/cognito OR /api/auth/callback/cognito
resource "aws_wafv2_regex_pattern_set" "cognito_login_paths" {
  name        = "cognito_login_paths"
  description = "Regex to match the login URIs"
  scope       = "REGIONAL"
  regular_expression {
    regex_string = "^\\/(api\\/auth\\/(signin|callback)\\/cognito)$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/auth\\/mfa$"
  }
}

#
# WAF ACL association with ALB
#

resource "aws_wafv2_web_acl_association" "form_viewer_assocation" {
  resource_arn = aws_lb.form_viewer.arn
  web_acl_arn  = aws_wafv2_web_acl.forms_acl.arn
}

#
# WAF ACL logging
#

resource "aws_wafv2_web_acl_logging_configuration" "firehose_waf_logs_forms" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.firehose_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.forms_acl.arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "valid_app_uri_paths" {
  name        = "valid_app_uri_paths"
  scope       = "REGIONAL"
  description = "Regex to match the app and api valid urls"

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(admin|id|api|auth|signup|profile|forms|unsupported-browser|terms-of-use|contact|support|404)(?:\\/[\\w-]+)?)(?:\\/.*)?$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(form-builder|sla|unlock-publishing|terms-and-conditions|javascript-disabled)(?:\\/[\\w-]+)?)(?:\\/.*)?$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(static|_next|img|favicon\\.ico)(?:\\/[\\w-]+)*)(?:\\/.*)?$"
  }

  # API paths
  regular_expression {
    regex_string = "^\\/(?:v1)?\\/?(?:(docs|status))(?:\\/)?$"
  }

  # This is a temporary rule to allow search engines tools to access ownership verification files
  regular_expression {
    regex_string = "^\\/?(BingSiteAuth\\.xml|googlef34bd8c094c26cb0\\.html)$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?$"
  }
}

resource "aws_wafv2_regex_pattern_set" "forms_base_url" {
  name        = "forms_base_url"
  description = "Regex matching the root domain of GCForms"
  scope       = "REGIONAL"
  dynamic "regular_expression" {
    for_each = local.all_domains
    content {
      regex_string = "^${regular_expression.value}$"
    }
  }
}

resource "aws_wafv2_web_acl" "forms_maintenance_mode_acl" {
  # checkov:skip=CKV2_AWS_31: Logging configuration not required
  name  = "GCFormsMaintenanceMode"
  scope = "CLOUDFRONT"

  provider = aws.us-east-1

  default_action {
    block {}
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AllowGetOnMaintenancePageHTMLResources"
    priority = 3

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = "GET"
            positional_constraint = "EXACTLY"

            field_to_match {
              method {}
            }

            text_transformation {
              priority = 1
              type     = "NONE"
            }
          }
        }

        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.valid_maintenance_mode_uri_paths.arn

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 1
              type     = "COMPRESS_WHITE_SPACE"
            }

            text_transformation {
              priority = 2
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AllowGetOnMaintenancePageHTMLResources"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "forms_maintenance_mode_global_rule"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_regex_pattern_set" "valid_maintenance_mode_uri_paths" {
  name        = "valid_maintenance_page_uri_paths"
  scope       = "CLOUDFRONT"
  description = "Regex to match the maintenance page valid URIs"

  provider = aws.us-east-1

  regular_expression {
    regex_string = "^\\/(index.html|index-fr.html|style.css|site-unavailable.svg|favicon.ico)?$"
  }
}

#
# IPv4 blocklist that is automatically managed by a Lambda function.  Any IP address in the WAF logs
# that crosses a block threshold will be added to the blocklist.
#
module "waf_ip_blocklist" {
  source = "github.com/cds-snc/terraform-modules//waf_ip_blocklist?ref=cb640e42f6a3dfe51cce4c702998e611fff48903" # v10.0.1

  service_name                     = "forms_app"
  athena_database_name             = "access_logs"
  athena_query_results_bucket      = "forms-${var.env}-athena-bucket"
  athena_query_source_bucket       = var.cbs_satellite_bucket_name
  athena_workgroup_name            = "primary"
  waf_rule_ids_skip                = ["BlockLargeRequests", "RateLimitersRuleGroup"]
  athena_lb_table_name             = "lb_logs"
  query_lb                         = true
  query_waf                        = false
  waf_block_threshold              = 50
  waf_ip_blocklist_update_schedule = "rate(15 minutes)"
  billing_tag_value                = "forms"
}
