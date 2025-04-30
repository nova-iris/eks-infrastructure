# Applications module - This serves as a template for deploying applications to the EKS cluster
# When adding new applications, consider following this pattern:

# Example of how to create a namespace for a team or application
# resource "kubernetes_namespace" "example" {
#   metadata {
#     name = "example-namespace"
#     
#     labels = {
#       environment = "production"
#       team        = "platform"
#     }
#   }
# }

# Example of how to deploy an application using Helm
# resource "helm_release" "example_app" {
#   name             = "example-app"
#   repository       = "https://example-repo.github.io/charts"
#   chart            = "example-chart"
#   version          = "1.0.0"
#   namespace        = kubernetes_namespace.example.metadata[0].name
#   create_namespace = false
#   
#   values = [
#     file("${path.module}/values/example_values.yaml")
#   ]
#   
#   set {
#     name  = "service.type"
#     value = "ClusterIP"
#   }
# }

# For new applications, follow this organizational structure:
# 1. Group related applications by domain/team
# 2. Store values files in the values/ directory
# 3. Use dependencies to ensure proper deployment order
