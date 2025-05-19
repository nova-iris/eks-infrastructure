variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources to"
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

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster is deployed"
  type        = string
}

variable "cert_manager_version" {
  description = "Version of cert-manager to install"
  type        = string
}

variable "aws_load_balancer_controller_version" {
  description = "Version of AWS Load Balancer Controller to install"
  type        = string
}

variable "external_dns_version" {
  description = "Version of External DNS to install"
  type        = string
}

variable "argocd_version" {
  description = "Version of ArgoCD to install"
  type        = string
}

variable "external_secrets_version" {
  description = "Version of External Secrets to install"
  type        = string
  default     = "0.9.9"
}

variable "ebs_csi_driver_version" {
  description = "Version of AWS EBS CSI Driver to install"
  type        = string
  default     = "2.26.1"
}

variable "enable_ebs_csi_driver" {
  description = "Whether to enable the AWS EBS CSI Driver"
  type        = bool
  default     = false
}

variable "efs_csi_driver_version" {
  description = "Version of AWS EFS CSI Driver to install"
  type        = string
  default     = "2.5.2"
}

variable "enable_efs_csi_driver" {
  description = "Whether to enable the AWS EFS CSI Driver"
  type        = bool
  default     = false
}

variable "rancher_version" {
  description = "Version of Rancher to install"
  type        = string
  default     = "2.8.2"
}

variable "external_secrets_version" {
  description = "Version of External Secrets to install"
  type        = string
  default     = "0.9.9"
}
