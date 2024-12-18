# Hello World Kubernetes Application with Terraform

## Project Overview

This project uses Terraform to:

- Deploy an AWS EKS (Elastic Kubernetes Service) cluster.
- Set up a VPC with public and private subnets.
- Deploy a "Hello World" web application using Kubernetes resources (Deployment, Service).
- Set up Kubernetes Ingress to expose the application externally.
- Optionally use a custom domain purchased from Namecheap and configure DNS with Route53.

## Prerequisites

- **AWS Account**: With required permissions.
- **AWS CLI**: Installed and configured.
- **Terraform**: Installed.
- **kubectl**: Installed.
- **SSH Key Pair**: Public key available.
- **Helm**: Installed.
- **Custom Domain**: Purchased from Namecheap or another provider.
- **Route53 Hosted Zone**: For your domain name.

## Project Setup Instructions

### 1. Clone the Repository
```
git clone https://github.com/augustinewong715/heals-demo
```

```
cd heals-demo
```

### 2. Configure Variables
Update variables.tf:

Set aws_region if different from the default.
Set cluster_name if desired.
Set domain_name to your custom domain (e.g., "example.com").
Set hosted_zone_id to your Route53 hosted zone ID.

### 3. Initialize Terraform

```
terraform init
```

### 4. Review the Plan

```
terraform plan
```

Ensure all resources are planned as expected.

### 5. Apply the Configuration

```
terraform apply
```

Type yes when prompted to confirm the changes.

Note: The EKS cluster creation can take up to 25 minutes.

## Testing the Application

### Retrieve the Ingress URL After deployment, obtain the Ingress URL from the Terraform outputs.

### Access the Application Open your web browser and navigate to the Ingress URL appended with /hello. For example:

http://cluster-endpoint/hello

You should see the "Hello World" page served by the application.