locals {
  # Map: key (availability zone ID) => value (firewall endpoint ID)
  networkfirewall_endpoints = { for i in aws_networkfirewall_firewall.forms.firewall_status[0].sync_states : i.availability_zone => i.attachment[0].endpoint_id }
  public_subnet_cidrs       = { for index, sub in aws_subnet.forms_public.*.cidr_block : index + 1 => sub }
}

resource "aws_networkfirewall_firewall" "forms" {
  #checkov:skip=CKV_AWS_345: AWS Managed Key is enough encryption for this use case

  name                   = "GCForms"
  description            = "Firewall limiting outbound traffic.  WAF handles inbound"
  delete_protection      = true
  vpc_id                 = aws_vpc.forms.id
  firewall_policy_arn    = aws_networkfirewall_firewall_policy.forms.arn
  enabled_analysis_types = ["HTTP_HOST", "TLS_SNI"]
  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall.*.id
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
    policy_variables {
      rule_variables {
        key = "HOME_NET"
        ip_set {
          definition = [var.vpc_cidr_block]
        }
      }
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.suricata_rules.arn
    }

  }
}

resource "aws_networkfirewall_rule_group" "suricata_rules" {
  #checkov:skip=CKV_AWS_345: AWS Managed Key is enough encryption for this use case
  capacity    = 500
  name        = "GCForms"
  description = "Only allow web traffic and deny everything else"
  type        = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_string = file("./firewall_rules/suricata.rules")
    }
  }



}

resource "aws_networkfirewall_logging_configuration" "forms" {
  firewall_arn                = aws_networkfirewall_firewall.forms.arn
  enable_monitoring_dashboard = true
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.forms_alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.forms_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

#
# Firewall CloudWatch log group
#
resource "aws_cloudwatch_log_group" "forms_alert" {
  # checkov:skip=CKV_AWS_338: WAF and Firewall logs are only kept for 14 days 
  name              = "Network-Firewall-Alert"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "forms_flow" {
  # checkov:skip=CKV_AWS_338: WAF and Firewall logs are only kept for 14 days 
  name              = "Network-Firewall-Flow"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 7
}
