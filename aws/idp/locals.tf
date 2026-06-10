locals {
  hosted_zone_id    = var.hosted_zone_ids[0]
  protocol_versions = toset(["HTTP1", "HTTP2"])
  idp_domains       = [for domain in var.domains : "auth.${domain}"]
}
