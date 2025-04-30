

data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}
