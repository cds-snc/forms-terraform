locals {
  excluded_common_rules = [
    "EC2MetaDataSSRF_BODY",           # Rule is blocking IdP OIDC app creation
    "EC2MetaDataSSRF_QUERYARGUMENTS", # Rule is blocking IdP OIDC login
    "SizeRestrictions_BODY"           # Default size rule of 8Kb is too restrictive
  ]
}

resource "aws_wafv2_web_acl" "idp" {
  name  = "idp"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockLargeRequests"
    priority = 3

    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          size_constraint_statement {
            field_to_match {
              cookies {
                match_pattern {
                  all {}
                }
                match_scope       = "ALL"
                oversize_handling = "MATCH"
              }
            }
            comparison_operator = "GT"
            size                = 8192
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          size_constraint_statement {
            field_to_match {
              headers {
                match_pattern {
                  all {}
                }
                match_scope       = "ALL"
                oversize_handling = "MATCH"
              }
            }
            comparison_operator = "GT"
            size                = 8192
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockLargeRequests"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "InvalidHost"
    priority = 5

    action {
      block {}
    }

    statement {
      not_statement {
        // statement {
        // The OR statement is commented out until we have more then one domain to check against
        // or_statement {
        dynamic "statement" {
          for_each = local.idp_domains
          content {
            byte_match_statement {
              positional_constraint = "EXACTLY"
              field_to_match {
                single_header {
                  name = "host"
                }
              }
              search_string = statement.value
              text_transformation {
                priority = 1
                type     = "COMPRESS_WHITE_SPACE"
              }
              text_transformation {
                priority = 1
                type     = "LOWERCASE"
              }
              //        }
              //        }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "InvalidHost"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

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
    priority = 20

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.rate_limiters_group_idp.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate_limiters_rule_group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30
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
    priority = 40
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
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = local.excluded_common_rules
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
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "idp"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "BlockedIPv4"
    priority = 70

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = var.waf_ipv4_blocklist_arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockedIPv4"
      sampled_requests_enabled   = true
    }
  }

  tags = local.common_tags
}

resource "aws_wafv2_rule_group" "rate_limiters_group_idp" {
  capacity = 32 // 2, as a base cost. For each custom aggregation key that you specify, add 30 WCUs.
  name     = "RateLimitersGroupIdP"
  scope    = "REGIONAL"

  rule {
    name     = "BlanketRequestLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 5000
        aggregate_key_type = "IP"

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
        limit              = 1000
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
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitersGroup"
    sampled_requests_enabled   = false
  }

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "idp" {
  resource_arn = aws_lb.idp.arn
  web_acl_arn  = aws_wafv2_web_acl.idp.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "idp" {
  log_destination_configs = [var.kinesis_firehose_waf_logs_arn]
  resource_arn            = aws_wafv2_web_acl.idp.arn

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
