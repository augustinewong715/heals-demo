# provider.tf

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.demo.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.demo.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}