module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Add cluster addons
  cluster_addons = var.cluster_addons

  eks_managed_node_groups = {
    default = {
      # Use node_group object with fallback to individual variables for backward compatibility
      min_size     = var.min_size != null ? var.min_size : var.node_group.min_size
      max_size     = var.max_size != null ? var.max_size : var.node_group.max_size
      desired_size = var.desired_size != null ? var.desired_size : var.node_group.desired_size

      instance_types = var.instance_types != null ? var.instance_types : var.node_group.instance_types
      capacity_type  = var.capacity_type != null ? var.capacity_type : var.node_group.capacity_type

      labels = var.node_labels != null ? var.node_labels : var.node_group.node_labels
      tags   = var.tags
    }
  }

  tags = var.tags
}

# Data source to get the authentication token for the EKS cluster
data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}
