# Main entrypoint for the EKS infrastructure
# Organizes resources into logical modules for better maintainability

# Core infrastructure module (VPC, EKS)
module "infrastructure" {
  source = "./infrastructure"

  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  vpc_cidr                = var.vpc_cidr
  aws_region              = var.aws_region
  eks_managed_node_groups = var.eks_managed_node_groups
  cluster_addons          = var.cluster_addons
  default_tags            = var.default_tags
  route53_hosted_zone_id  = var.route53_hosted_zone_id
}

# Cluster add-ons module (Load Balancer Controller, External DNS, Cert Manager, ArgoCD)
module "addons" {
  source = "./addons"

  cluster_name            = var.cluster_name
  aws_region              = var.aws_region
  eks_oidc_provider_arn   = module.infrastructure.oidc_provider_arn
  cluster_oidc_issuer_url = module.infrastructure.cluster_oidc_issuer_url
  vpc_id                  = module.infrastructure.vpc_id

  # Karpenter configuration
  enable_karpenter  = var.enable_karpenter
  karpenter_version = var.karpenter_version

  depends_on = [module.infrastructure]
}

# Applications module - For deploying applications to the cluster
module "applications" {
  source = "./applications"

  # Only deploy this when needed - commented out by default
  count = 0

  cluster_name            = var.cluster_name
  aws_region              = var.aws_region
  vpc_id                  = module.infrastructure.vpc_id
  eks_oidc_provider_arn   = module.infrastructure.oidc_provider_arn
  cluster_oidc_issuer_url = module.infrastructure.cluster_oidc_issuer_url
  route53_zone_id         = module.infrastructure.route53_zone_id
  route53_zone_name       = module.infrastructure.route53_zone_name

  depends_on = [module.addons]
}
