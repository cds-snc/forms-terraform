locals {
  s3_origin_id = "MaintenanceMode"
}

resource "aws_cloudfront_origin_access_identity" "maintenance_mode" {
  comment = "Access Identity for the Maintenance Website"
}

resource "aws_cloudfront_distribution" "maintenance_mode" {
  # checkov:skip=CKV_AWS_68: WAF ACL not required
  # checkov:skip=CKV_AWS_86: Access logging not required
  enabled             = true
  http_version        = "http2"
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.forms_maintenance_mode_acl.arn
  price_class         = "PriceClass_100"

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.maintenance_mode.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.maintenance_mode.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    compress         = true
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.form_viewer_maintenance_mode.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

  depends_on = [
    aws_s3_bucket.maintenance_mode
  ]
}