resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "Policy for External Secrets to access AWS Secrets Manager and Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets-role"

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
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}

# Create the External Secrets namespace
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "external-secrets"
    }
  }
}

# Create service account for External Secrets
resource "kubectl_manifest" "external_secrets_sa" {
  depends_on = [kubernetes_namespace.external_secrets]

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: external-secrets
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.external_secrets.arn}
YAML
}

# Deploy External Secrets using Helm
resource "helm_release" "external_secrets" {
  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.external_secrets_sa
  ]

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = var.external_secrets_version
  create_namespace = false

  values = [
    templatefile("${path.module}/values/external-secrets.yaml", {
      role_arn   = aws_iam_role.external_secrets.arn,
      aws_region = var.aws_region
    })
  ]

  set {
    name  = "installCRDs"
    value = true
  }

  # Properly clean up CRDs when removing External Secrets
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete crd secretstores.external-secrets.io externalsecrets.external-secrets.io clustersecretstores.external-secrets.io || true"
  }
}

# Create example SecretStore for demonstration
resource "kubectl_manifest" "example_secret_store" {
  depends_on = [helm_release.external_secrets]

  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secretsmanager
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${var.aws_region}
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
YAML
}