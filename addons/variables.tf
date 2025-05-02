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
  default     = "v1.17.1"
}

variable "aws_load_balancer_controller_version" {
  description = "Version of AWS Load Balancer Controller to install"
  type        = string
  default     = "1.12.0"
}

variable "external_dns_version" {
  description = "Version of External DNS to install"
  type        = string
  default     = "6.20.0"
}

variable "argocd_version" {
  description = "Version of ArgoCD to install"
  type        = string
  default     = "7.8.15"
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

variable "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler to install"
  type        = string
  default     = "9.29.3"
}

variable "enable_cluster_autoscaler" {
  description = "Whether to enable the Kubernetes Cluster Autoscaler"
  type        = bool
  default     = true
}
