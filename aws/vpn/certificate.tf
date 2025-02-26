resource "aws_acm_certificate" "vpn" {
  private_key       = file("./certificates/aws-development-server.key")
  certificate_body  = file("./certificates/aws-development-server.crt")
  certificate_chain = file("./certificates/ca.crt")

  lifecycle {
    create_before_destroy = true
  }
}