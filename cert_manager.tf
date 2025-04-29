resource "aws_iam_policy" "cert_manager" {
  name        = "cert-manager-acme-dns01-route53"
  description = "This policy allows cert-manager to manage ACME DNS01 records in Route53 hosted zones. See https://cert-manager.io/docs/configuration/acme/dns01/route53"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

# Create a dedicated IAM role for DNS01 resolver that matches the eksctl approach
resource "aws_iam_role" "cert_manager_dns01" {
  name = "cert-manager-acme-dns01-route53"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        # Condition = {
        #   StringEquals = {
        #     "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:cert-manager:cert-manager-acme-dns01-route53"
        #   }
        # }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_dns01" {
  policy_arn = aws_iam_policy.cert_manager.arn
  role       = aws_iam_role.cert_manager_dns01.name
}

resource "helm_release" "cert_manager" {
  depends_on = [
    aws_iam_role_policy_attachment.cert_manager_dns01,
    helm_release.aws_load_balancer_controller
  ]

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = var.cert_manager_version
  create_namespace = true

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

  #   # Enable for troubleshooting
  #   set {
  #     name  = "global.logLevel"
  #     value = "4"
  #   }

  #   # Enable leader election to ensure high availability
  #   set {
  #     name  = "leaderElection.namespace"
  #     value = "cert-manager"
  #   }
}

# Create service account for DNS01 Route53 integration
resource "kubectl_manifest" "cert_manager_acme_dns01_route53_sa" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cert-manager-acme-dns01-route53
  namespace: cert-manager
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
  namespace: cert-manager
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
  namespace: cert-manager
subjects:
  - kind: ServiceAccount
    name: cert-manager
    namespace: cert-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cert-manager-acme-dns01-route53-tokenrequest
YAML
}

# ClusterIssuer for cert-manager (Let's Encrypt staging)
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
          role: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cert-manager-acme-dns01-route53
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager-acme-dns01-route53
YAML
}

# ClusterIssuer for cert-manager (Let's Encrypt production)
# resource "kubectl_manifest" "letsencrypt_prod_issuer" {
#   depends_on = [
#     helm_release.cert_manager,
#     kubectl_manifest.cert_manager_acme_dns01_route53_sa,
#     kubectl_manifest.cert_manager_acme_dns01_route53_role,
#     kubectl_manifest.cert_manager_acme_dns01_route53_rolebinding
#   ]

#   yaml_body = <<YAML
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: admin@novairis.dev
#     privateKeySecretRef:
#       name: letsencrypt-prod
#     solvers:
#     - dns01:
#         route53:
#           region: ${var.aws_region}
#           auth:
#             kubernetes:
#               serviceAccountRef:
#                 name: cert-manager-acme-dns01-route53
#                 namespace: cert-manager
#       selector:
#         dnsZones:
#         - "${data.aws_route53_zone.selected.name}"
#     - http01:
#         ingress:
#           class: alb
# YAML
# }
