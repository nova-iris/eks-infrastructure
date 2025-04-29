resource "aws_iam_policy" "cert_manager" {
  name        = "${var.cluster_name}-cert-manager-policy"
  description = "Policy for Cert-Manager to manage DNS records for DNS01 challenges"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${var.route53_hosted_zone_id}",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName",
          "route53:ListHostedZones"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role" "cert_manager" {
  name = "${var.cluster_name}-cert-manager-role"

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
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cert-manager"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  policy_arn = aws_iam_policy.cert_manager.arn
  role       = aws_iam_role.cert_manager.name
}

# Create a dedicated IAM role for DNS01 resolver
resource "aws_iam_role" "cert_manager_dns01" {
  name = "${var.cluster_name}-cert-manager-dns01-role"

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
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cert-manager-acme-dns01-route53"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_dns01" {
  policy_arn = aws_iam_policy.cert_manager.arn
  role       = aws_iam_role.cert_manager_dns01.name
}

resource "helm_release" "cert_manager" {
  depends_on = [aws_iam_role_policy_attachment.cert_manager]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "kube-system"
  version    = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "cert-manager"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager.arn
  }
}

# Create service account for DNS01 Route53 integration
resource "kubectl_manifest" "cert_manager_acme_dns01_route53_sa" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cert-manager-acme-dns01-route53
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.cert_manager_dns01.arn}
YAML
}

# Role to allow cert-manager to create tokens for the Route53 service account
resource "kubectl_manifest" "cert_manager_acme_dns01_route53_role" {
  depends_on = [helm_release.cert_manager, kubectl_manifest.cert_manager_acme_dns01_route53_sa]

  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cert-manager-acme-dns01-route53-tokenrequest
  namespace: kube-system
rules:
  - apiGroups: ['']
    resources: ['serviceaccounts/token']
    resourceNames: ['cert-manager-acme-dns01-route53']
    verbs: ['create']
YAML
}

# RoleBinding to bind the role to cert-manager's service account
resource "kubectl_manifest" "cert_manager_acme_dns01_route53_rolebinding" {
  depends_on = [helm_release.cert_manager, kubectl_manifest.cert_manager_acme_dns01_route53_role]

  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cert-manager-acme-dns01-route53-tokenrequest
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: cert-manager
    namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cert-manager-acme-dns01-route53-tokenrequest
YAML
}

# ClusterIssuer for cert-manager (Let's Encrypt staging) - Simplified configuration
resource "kubectl_manifest" "letsencrypt_staging_issuer" {
  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.cert_manager_acme_dns01_route53_sa,
    kubectl_manifest.cert_manager_acme_dns01_route53_role,
    kubectl_manifest.cert_manager_acme_dns01_route53_rolebinding
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@novairis.dev
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        route53:
          region: ${var.aws_region}
          # Using ambient credentials mode without role reference for simplicity
        auth:
          kubernetes:
            serviceAccountRef:
              name: cert-manager-acme-dns01-route53
              namespace: kube-system
      selector:
        dnsZones:
        - "${data.aws_route53_zone.selected.name}"
    - http01:
        ingress:
          class: alb
YAML
}

# Let's try an alternative simpler approach with a direct ClusterIssuer
resource "kubectl_manifest" "letsencrypt_direct_issuer" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-direct
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@novairis.dev
    privateKeySecretRef:
      name: letsencrypt-direct
    solvers:
    - http01:
        ingress:
          class: alb
YAML
}
