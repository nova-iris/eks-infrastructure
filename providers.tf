terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Using the token directly from the infrastructure module
provider "kubernetes" {
  host                   = module.infrastructure.cluster_endpoint
  cluster_ca_certificate = base64decode(module.infrastructure.cluster_certificate_authority_data)
  token                  = module.infrastructure.cluster_token
}

# Using the token directly from the infrastructure module for Helm provider
provider "helm" {
  kubernetes {
    host                   = module.infrastructure.cluster_endpoint
    cluster_ca_certificate = base64decode(module.infrastructure.cluster_certificate_authority_data)
    token                  = module.infrastructure.cluster_token
  }
}

# Using the token directly from the infrastructure module for kubectl provider
provider "kubectl" {
  host                   = module.infrastructure.cluster_endpoint
  cluster_ca_certificate = base64decode(module.infrastructure.cluster_certificate_authority_data)
  token                  = module.infrastructure.cluster_token
  load_config_file       = true
}
