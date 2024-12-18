# provider.tf

provider "aws" {
  region = var.aws_region
}

# Data sources for EKS cluster
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.demo.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.demo.name
}

# Kubernetes Provider with explicit dependency
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token

}

# Helm Provider with explicit dependency
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}