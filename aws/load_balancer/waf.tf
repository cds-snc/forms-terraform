#
# WAF
# Defines the firewall rules protecting the ALB
#

locals {
  is_production = var.env == "production"

  # AWSManagedRulesCommonRuleSet to exclude.  Only exclude XSS in non-production environments.
  excluded_rules_upload = ["GenericRFI_QUERYARGUMENTS", "GenericRFI_BODY", "SizeRestrictions_BODY"]
  excluded_xss          = ["CrossSiteScripting_BODY"]
  excluded_rules_common = !local.is_production ? concat(local.excluded_rules_upload, local.excluded_xss) : local.excluded_rules_upload
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
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

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
    priority = 3
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
    priority = 4
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

  rule {
    name     = "PostRequestLimit"
    priority = 102

    # Only block in `production`
    action {
      dynamic "block" {
        for_each = local.is_production ? [true] : []
        content {}
      }
      dynamic "count" {
        for_each = !local.is_production ? [true] : []
        content {}
      }
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
    # make sure to update line 33 of output.tf if you change the name of the rule
    name     = "TemporaryTokenGeneratedOutsideCanada"
    priority = 5

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
          byte_match_statement {

            field_to_match {
              uri_path {}
            }

            positional_constraint = "CONTAINS"
            search_string         = "/api/token/temporary"

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
      metric_name                = "TemporaryTokenGeneratedOutsideCanada"
      cloudwatch_metrics_enabled = true
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
