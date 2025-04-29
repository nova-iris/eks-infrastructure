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
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:argocd:argocd-server"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd" {
  policy_arn = aws_iam_policy.argocd.arn
  role       = aws_iam_role.argocd.name
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = var.argocd_version
  create_namespace = true
  depends_on       = [aws_iam_role_policy_attachment.argocd]

  # High availability configuration
  set {
    name  = "controller.replicas"
    value = "2"
  }

  set {
    name  = "server.replicas"
    value = "2"
  }

  set {
    name  = "repoServer.replicas"
    value = "2"
  }

  set {
    name  = "applicationSet.replicas"
    value = "2"
  }

  # Enable TLS for ArgoCD using cert-manager
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.novairis.dev"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.novairis.dev"
  }

  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls-cert"
  }

  # Enhanced ALB annotations
  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTPS\": 443}]"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = "dummy-value" # This will be overridden by cert-manager
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/group\\.name"
    value = "argocd-ingress-group"
  }

  set {
    name  = "server.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = "argocd.novairis.dev"
  }

  set {
    name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-direct"
  }

  # Configure service account with IRSA
  set {
    name  = "server.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "server.serviceAccount.name"
    value = "argocd-server"
  }

  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.argocd.arn
  }

  # Make sure ArgoCD server service is configured correctly
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}
