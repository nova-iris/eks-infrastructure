data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}

# Route53 outputs are defined in outputs.tf to keep all outputs in one place
