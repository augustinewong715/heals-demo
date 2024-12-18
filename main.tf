# main.tf


####################
# VPC Configuration
####################

resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks-demo-vpc"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
  tags = {
    Name = "eks-demo-igw"
  }
}

resource "aws_subnet" "demo" {
  count                   = 2
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-demo-subnet-${count.index}"
  }
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }
  tags = {
    Name = "eks-demo-rt"
  }
}

resource "aws_route_table_association" "demo" {
  count          = length(aws_subnet.demo)
  subnet_id      = aws_subnet.demo[count.index].id
  route_table_id = aws_route_table.demo.id
}

##########################
# EKS Cluster & Node Group
##########################

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

# Data source to get the list of availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}



# EKS Cluster
resource "aws_eks_cluster" "demo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.demo[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "eks_node" {
  name               = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS Node Group
resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "demo-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.demo[*].id

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.node_instance_type]

depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
}

#######################
# Kubernetes Resources
#######################

# Kubernetes Namespace
resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "hello_world" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "hello-world"
      }
    }
    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }
      spec {
        container {
          image = "nginxdemos/hello"
          name  = "hello-world"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Kubernetes Service
resource "kubernetes_service" "hello_world" {
  metadata {
    name      = "hello-world-service"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = {
      app = "hello-world"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "hello_world" {
  metadata {
    name      = "hello-world-ingress"
    namespace = kubernetes_namespace.demo.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "heals-demo.site"
      http {
        path {
          path      = "/hello"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.hello_world.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Install Nginx Ingress Controller using Helm
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    aws_eks_cluster.demo
  ]
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "kube-system"
  }
}

# Get the current AWS region
data "aws_region" "current" {}

# Map of AWS regions to ELB zone IDs
locals {
  elb_zone_ids = {
    "us-east-1"      = "Z26RNL4JYFTOTI"
    "ap-east-1"      = "Z3DQVH9N71FHZ0" 
    # Add other regions as needed
  }
  elb_zone_id = lookup(local.elb_zone_ids, data.aws_region.current.name, null)
}

resource "aws_route53_record" "heals_demo_site" {
  zone_id = "Z0757082Z76RR9T9GYNA" 
  
  name    = "heals-demo.site"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = local.elb_zone_id
    evaluate_target_health = false
  }
}

#######################
# Outputs
#######################

output "ingress_url" {
  description = "Ingress URL (app endpoint)"
  value       = "http://${aws_route53_record.heals_demo_site.name}/hello"
}
