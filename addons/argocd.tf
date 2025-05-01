resource "aws_iam_policy" "argocd" {
  name        = "${var.cluster_name}-argocd-policy"
  description = "Policy for ArgoCD to interact with AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "argocd" {
  name = "${var.cluster_name}-argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd" {
  policy_arn = aws_iam_policy.argocd.arn
  role       = aws_iam_role.argocd.name
}

# ArgoCD Helm Release - Must come before certificate creation
resource "helm_release" "argocd" {
  depends_on = [helm_release.cert_manager]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = var.argocd_version
  create_namespace = true

  values = [file("${path.module}/values/argocd.yaml")]
}

# Explicit Certificate resource to fix domain name mismatch
# Now depends on ArgoCD helm release to ensure namespace exists
resource "kubectl_manifest" "argocd_certificate" {
  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.letsencrypt_staging_issuer,
    helm_release.argocd # Added dependency to ensure namespace exists
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-tls-cert
  namespace: argocd
spec:
  secretName: argocd-tls-cert
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: argocd.novairis.dev
  dnsNames:
  - argocd.novairis.dev
YAML
}
