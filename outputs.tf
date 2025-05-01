output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.infrastructure.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.infrastructure.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.infrastructure.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.infrastructure.cluster_iam_role_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.infrastructure.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.infrastructure.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.infrastructure.public_subnets
}

output "route53_zone_name" {
  description = "Name of the Route53 zone"
  value       = module.infrastructure.route53_zone_name
}

output "route53_zone_id" {
  description = "ID of the Route53 zone"
  value       = module.infrastructure.route53_zone_id
}
