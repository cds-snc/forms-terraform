locals {
  # Map: key (availability zone ID) => value (firewall endpoint ID)
  networkfirewall_endpoints = { for i in aws_networkfirewall_firewall.forms.firewall_status[0].sync_states : i.availability_zone => i.attachment[0].endpoint_id }
  public_subnet_cidrs       = { for index, sub in aws_subnet.forms_public.*.cidr_block : index + 1 => sub }
}


resource "aws_networkfirewall_firewall" "forms" {
  #checkov:skip=CKV_AWS_345: AWS Managed Key is enough encryption for this use case

  name                = "GCForms"
  description         = "Firewall limiting outbound traffic.  WAF handles inbound"
  delete_protection   = true
  vpc_id              = aws_vpc.forms.id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.forms.arn
  dynamic "subnet_mapping" {
    for_each = aws_subnet.forms_public.*.id
    content {
      ip_address_type = "IPV4"
      subnet_id       = subnet_mapping.value
    }
  }
}


resource "aws_networkfirewall_firewall_policy" "forms" {
  #checkov:skip=CKV_AWS_346: AWS Managed Key is enough encryption for this use case
  name = "forms"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.known_external_domains_only.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.general.arn
    }

  }
}

resource "aws_networkfirewall_rule_group" "known_external_domains_only" {
  #checkov:skip=CKV_AWS_345: AWS Managed Key is enough encryption for this use case
  capacity    = 10
  name        = "known-external-domains-only"
  description = "Only allow traffic originating internally to reach known domains"
  type        = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI"]
        targets              = concat(["api.notification.canada.ca", "api.hcaptcha.com", "github.com"], [for domain in var.domains : ".${domain}"])
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "general" {
  #checkov:skip=CKV_AWS_345: AWS Managed Key is enough encryption for this use case
  capacity    = 10
  name        = "general"
  description = "Only allow web traffic and deny everything else"
  type        = "STATEFUL"
  rule_group {
    rules_source {
      dynamic "stateful_rule" {
        for_each = local.public_subnet_cidrs
        content {
          action = "PASS"
          header {
            destination      = stateful_rule.value
            destination_port = "ANY"
            protocol         = "HTTP"
            direction        = "FORWARD"
            source_port      = "ANY"
            source           = "ANY"
          }
          rule_option {
            keyword  = "sid"
            settings = ["${stateful_rule.key}"]
          }
        }
      }
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "IP"
          direction        = "ANY"
          source_port      = "ANY"
          source           = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["${length(aws_subnet.forms_public) + 1}"]
        }
      }
    }
  }
}

resource "aws_networkfirewall_logging_configuration" "forms" {
  firewall_arn                = aws_networkfirewall_firewall.forms.arn
  enable_monitoring_dashboard = true
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.forms.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

#
# Firewall CloudWatch log group
#
resource "aws_cloudwatch_log_group" "forms" {
  # checkov:skip=CKV_AWS_338: WAF and Firewall logs are only kept for 14 days 
  name              = "Network-Firewall"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 14
}