variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources to"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster is deployed"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "URL of the OIDC issuer for the EKS cluster"
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the Route53 hosted zone for DNS records"
  type        = string
}

variable "route53_zone_name" {
  description = "Name of the Route53 hosted zone for DNS records"
  type        = string
}
