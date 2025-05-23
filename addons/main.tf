data "aws_caller_identity" "current" {}

data "aws_route53_zone" "selected" {
  name = "novairis.dev"
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

# This file orchestrates all the addon components for the EKS cluster.
# Each component is defined in its own file for better maintainability.
#
# Components included:
# - AWS Load Balancer Controller
# - External DNS 
# - Cert Manager
# - ArgoCD
# - Rancher
# - External Secrets
# - AWS EBS CSI Driver
