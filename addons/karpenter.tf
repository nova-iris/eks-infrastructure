resource "aws_iam_policy" "karpenter_controller" {
  count       = var.enable_karpenter ? 1 : 0
  name        = "${var.cluster_name}-karpenter-policy"
  description = "Policy for Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ec2:DeleteLaunchTemplate",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceAttribute",
          "pricing:GetProducts",
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::*:role/*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter_interruption_queue[0].arn
      }
    ]
  })
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-controller-role"

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
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  count      = var.enable_karpenter ? 1 : 0
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
  role       = aws_iam_role.karpenter_controller[0].name
}

# SQS queue for node termination events
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-interruption-queue"

  sqs_managed_sse_enabled = true
  message_retention_seconds = 300
  
  tags = {
    Name = "${var.cluster_name}-karpenter-interruption-queue"
  }
}

# Create a node IAM role that the Karpenter controller can use for node bootstrapping
resource "aws_iam_role" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create individual policy attachments for the karpenter node role
resource "aws_iam_role_policy_attachment" "karpenter_node_eks_cni" {
  count      = var.enable_karpenter ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_eks_worker" {
  count      = var.enable_karpenter ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_read" {
  count      = var.enable_karpenter ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm_managed" {
  count      = var.enable_karpenter ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node[0].name
}

# Deploy Karpenter Helm chart
resource "helm_release" "karpenter" {
  count      = var.enable_karpenter ? 1 : 0
  depends_on = [aws_iam_role_policy_attachment.karpenter_controller]

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = "karpenter"
  create_namespace = true

  # Using template file for more complex values
  values = [
    templatefile("${path.module}/values/karpenter.yaml", {
      ROLE_ARN        = aws_iam_role.karpenter_controller[0].arn
      CLUSTER_NAME    = var.cluster_name
      CLUSTER_ENDPOINT = replace(data.aws_eks_cluster.cluster[0].endpoint, "https://", "")
    })
  ]

  # Additional configurations via set
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller[0].arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter_node[0].name
  }
}

# Create an IAM instance profile for Karpenter nodes
resource "aws_iam_instance_profile" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-KarpenterNodeInstanceProfile"
  role  = aws_iam_role.karpenter_node[0].name
}

# Get the EKS cluster data to use for the Karpenter configuration
data "aws_eks_cluster" "cluster" {
  count = var.enable_karpenter ? 1 : 0
  name  = var.cluster_name
}

# Create a default provisioner after Karpenter installation
resource "kubectl_manifest" "karpenter_provisioner" {
  count     = var.enable_karpenter ? 1 : 0
  depends_on = [helm_release.karpenter]

  yaml_body = <<YAML
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "m5.large", "m5.xlarge"]
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  provider:
    subnetSelector:
      kubernetes.io/cluster/${var.cluster_name}: "*"
    securityGroupSelector:
      kubernetes.io/cluster/${var.cluster_name}: "*"
    instanceProfile: ${var.enable_karpenter ? aws_iam_instance_profile.karpenter_node[0].name : ""}
    tags:
      karpenter.sh/discovery: ${var.cluster_name}
  ttlSecondsAfterEmpty: 30
YAML
}

# Add EventBridge rules for EC2 interruption notifications to SQS
resource "aws_cloudwatch_event_rule" "karpenter_interruption_rule" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-interruption"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = [
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance Rebalance Recommendation",
      "EC2 Instance Termination Warning"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_target" {
  count     = var.enable_karpenter ? 1 : 0
  rule      = aws_cloudwatch_event_rule.karpenter_interruption_rule[0].name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue[0].arn
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  count     = var.enable_karpenter ? 1 : 0
  queue_url = aws_sqs_queue.karpenter_interruption_queue[0].url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action    = "sqs:SendMessage",
        Resource  = aws_sqs_queue.karpenter_interruption_queue[0].arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.karpenter_interruption_rule[0].arn
          }
        }
      }
    ]
  })
}