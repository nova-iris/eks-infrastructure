data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}

# Route53 outputs have been moved to outputs.tf
# to centralize all outputs in one file
