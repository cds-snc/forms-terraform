#
# WAF
# Defines the firewall rules protecting the ALB
#

locals {
  # AWSManagedRulesCommonRuleSet to exclude.
  excluded_rules_common = ["GenericRFI_QUERYARGUMENTS", "GenericRFI_BODY", "SizeRestrictions_BODY"]
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

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PostRequestRateLimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "PreventHostInjections"
    priority = 3

    statement {
      not_statement {
        statement {
          regex_pattern_set_reference_statement {

            arn = aws_wafv2_regex_pattern_set.forms_base_url.*.arn

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
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = local.excluded_rules_common
          content {
            name = excluded_rule.value
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
    priority = 6
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
    priority = 7
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }



  rule {
    name     = "AllowOnlyAppUrls"
    priority = 4

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
  description = "Regex to match the app valid urls"

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(admin|id|api|auth|signup|profile|forms|unsupported-browser|terms-of-use|404)(?:\\/[\\w-]+)?)(?:\\/.*)?$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(form-builder|sla|unlock-publishing|terms-and-conditions|javascript-disabled)(?:\\/[\\w-]+)?)(?:\\/.*)?$"
  }

  regular_expression {
    regex_string = "^\\/(?:en|fr)?\\/?(?:(static|_next|img|favicon\\.ico)(?:\\/[\\w-]+)*)(?:\\/.*)?$"
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
    for_each = var.domain
    content {
      regex_string = "^${regular_expression.value}$"
    }
  }
}

