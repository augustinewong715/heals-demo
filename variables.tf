
variable "aws_region" {
  description = "AWS region"
  default     = "ap-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "hello-world-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  default     = "t3.small"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  default     = 2
}

variable "domain_name" {
  description = "Your Route 53 domain name"
  default     = "heals-demo.site"
}

variable "hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone"
  type        = string
  default     = "Z0757082Z76RR9T9GYNA" # Replace with your actual hosted zone ID
}