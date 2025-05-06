data "aws_route53_zone" "selected" {
  count   = var.create_route53_zone ? 0 : 1
  zone_id = var.route53_hosted_zone_id
}

resource "aws_route53_zone" "new_zone" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = var.domain_name
    Environment = var.environment
    Terraform   = "true"
  }
}

# Use local variable to simplify referencing the zone ID and name regardless of whether it was created or referenced
locals {
  route53_zone_id   = var.create_route53_zone ? aws_route53_zone.new_zone[0].zone_id : data.aws_route53_zone.selected[0].zone_id
  route53_zone_name = var.create_route53_zone ? aws_route53_zone.new_zone[0].name : data.aws_route53_zone.selected[0].name
}

# Route53 outputs have been moved to outputs.tf
# to centralize all outputs in one file
