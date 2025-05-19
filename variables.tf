variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Terraform   = "true"
    Project     = "eks-infrastructure"
  }
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group configurations"
  type = object({
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = string
    node_labels    = map(string)
  })

  default = {
    min_size       = 1
    max_size       = 5
    desired_size   = 3
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    node_labels = {
      "cluster-autoscaler-enabled" = "true"
    }
  }
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type        = any
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent          = true
      configuration_values = "{\"env\":{\"WARM_ENI_TARGET\":\"2\",\"WARM_IP_TARGET\":\"5\"}}"
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

variable "route53_hosted_zone_id" {
  description = "ID of the Route53 hosted zone for external-dns"
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 hosted zone instead of using an existing one"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for the Route53 hosted zone to create if create_route53_zone is true"
  type        = string
  default     = "novairis.dev"
}

variable "environment" {
  description = "Environment name for tagging resources"
  type        = string
  default     = "dev"
}

variable "cert_manager_version" {
  description = "Version of the cert-manager Helm chart"
  type        = string
  default     = "v1.17.1"
}

variable "external_dns_version" {
  description = "Version of the external-dns Helm chart"
  type        = string
  default     = "1.16.1"
}

variable "aws_load_balancer_controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.12.0"
}

variable "argocd_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "7.8.15"
}

variable "enable_ebs_csi_driver" {
  description = "Whether to enable the AWS EBS CSI Driver addon"
  type        = bool
  default     = false
}

variable "enable_efs_csi_driver" {
  description = "Whether to enable the AWS EFS CSI Driver addon"
  type        = bool
  default     = false
}
