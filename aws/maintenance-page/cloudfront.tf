resource "aws_cloudfront_distribution" "wordpress" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_lb.wordpress.dns_name
    origin_id   = aws_lb.wordpress.name

    custom_header {
      name  = var.cloudfront_custom_header_name
      value = var.cloudfront_custom_header_value
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_lb.wordpress.name

    forwarded_values {
      query_string = true
      headers      = ["Host", "Options", "Referer", "Authorization", "strict-transport-security", "Content-Security-Policy", "X-XSS-Protection", "X-Frame-Options", "X-Content-Type-Options"]
      cookies {
        forward = "whitelist"
        whitelisted_names = [
          "comment_author_*",
          "comment_author_email_*",
          "comment_author_url_*",
          "wordpress_*",
          "wp-*"
        ]
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 1
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}