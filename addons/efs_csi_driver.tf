resource "aws_iam_policy" "efs_csi_driver" {
  count       = var.enable_efs_csi_driver ? 1 : 0
  name        = "${var.cluster_name}-efs-csi-driver-policy"
  description = "Policy for AWS EFS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0
  name  = "${var.cluster_name}-efs-csi-driver-role"

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
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  count      = var.enable_efs_csi_driver ? 1 : 0
  policy_arn = aws_iam_policy.efs_csi_driver[0].arn
  role       = aws_iam_role.efs_csi_driver[0].name
}

# Create a new EFS file system if enabled
resource "aws_efs_file_system" "eks_efs" {
  count          = var.enable_efs_csi_driver ? 1 : 0
  creation_token = "${var.cluster_name}-efs"

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

# Create mount targets in each subnet
data "aws_subnets" "private" {
  count = var.enable_efs_csi_driver ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

resource "aws_security_group" "efs" {
  count       = var.enable_efs_csi_driver ? 1 : 0
  name        = "${var.cluster_name}-efs-sg"
  description = "Allow EFS traffic from EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS from EKS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}

resource "aws_efs_mount_target" "eks_efs_mount" {
  count           = var.enable_efs_csi_driver ? length(data.aws_subnets.private[0].ids) : 0
  file_system_id  = aws_efs_file_system.eks_efs[0].id
  subnet_id       = data.aws_subnets.private[0].ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}

# Install EFS CSI Driver with Helm
resource "helm_release" "aws_efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0
  depends_on = [
    aws_iam_role_policy_attachment.efs_csi_driver,
    aws_efs_mount_target.eks_efs_mount
  ]

  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
  version    = var.efs_csi_driver_version

  values = [
    templatefile("${path.module}/values/efs-csi-driver.yaml", {
      role_arn           = aws_iam_role.efs_csi_driver[0].arn
      efs_file_system_id = aws_efs_file_system.eks_efs[0].id
    })
  ]

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "node.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "node.serviceAccount.name"
    value = "efs-csi-node-sa"
  }
}

# Create a PersistentVolumeClaim example for EFS
resource "kubectl_manifest" "efs_storage_class" {
  count      = var.enable_efs_csi_driver ? 1 : 0
  depends_on = [helm_release.aws_efs_csi_driver]
  yaml_body  = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.eks_efs[0].id}
  directoryPerms: "700"
  basePath: "/"
reclaimPolicy: Delete
volumeBindingMode: Immediate
YAML
}
