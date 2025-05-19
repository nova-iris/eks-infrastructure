resource "aws_iam_policy" "rancher" {
  name        = "${var.cluster_name}-rancher-policy"
  description = "Policy for Rancher to interact with AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "rancher" {
  name = "${var.cluster_name}-rancher-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:cattle-system:rancher"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rancher" {
  policy_arn = aws_iam_policy.rancher.arn
  role       = aws_iam_role.rancher.name
}

# Create the Rancher namespace 
# resource "kubernetes_namespace" "rancher" {
#   metadata {
#     name = "cattle-system"

#     labels = {
#       "app.kubernetes.io/managed-by" = "terraform"
#       "app.kubernetes.io/part-of"    = "rancher"
#     }
#   }
# }

# Create service account for Rancher
# resource "kubectl_manifest" "rancher_sa" {
#   depends_on = [kubernetes_namespace.rancher]

#   yaml_body = <<YAML
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: rancher
#   namespace: cattle-system
#   annotations:
#     eks.amazonaws.com/role-arn: ${aws_iam_role.rancher.arn}

# YAML
# }

# Deploy Rancher Helm chart
resource "helm_release" "rancher" {
  depends_on = [
    helm_release.cert_manager
    # kubectl_manifest.rancher_sa,
  ]

  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  namespace        = "cattle-system"
  version          = var.rancher_version
  create_namespace = true

  values = [file("${path.module}/values/rancher.yaml")]

  set {
    name  = "hostname"
    value = "rancher.novairis.dev"
  }

  # Wait for deployment to complete
  timeout = 600

  # Properly clean up CRDs when removing Rancher
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "kubectl -n cattle-system delete ingress,secret,service -l app=rancher || true"
  # }
}

# Certificate resource for Rancher
resource "kubectl_manifest" "rancher_certificate" {
  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.letsencrypt_staging_issuer,
    helm_release.rancher # Added dependency to ensure namespace exists
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: rancher-tls-cert
  namespace: cattle-system
spec:
  secretName: rancher-tls-cert
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: rancher.novairis.dev
  dnsNames:
  - rancher.novairis.dev
YAML
}

# Create DNS record for Rancher
# resource "kubectl_manifest" "rancher_dns_record" {
#   depends_on = [
#     helm_release.external_dns,
#     helm_release.rancher
#   ]

#   yaml_body = <<YAML
# apiVersion: externaldns.k8s.io/v1alpha1
# kind: DNSEndpoint
# metadata:
#   name: rancher-dns-record
#   namespace: cattle-system
# spec:
#   endpoints:
#   - dnsName: rancher.novairis.dev
#     recordTTL: 180
#     recordType: CNAME
#     targets:
#     - ${var.cluster_name}-rancher.elb.${var.aws_region}.amazonaws.com
# YAML
# }
