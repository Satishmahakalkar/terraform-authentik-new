provider "aws" {
  region = "us-east-1"
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets from the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get subnet details
data "aws_subnet" "all_subnets" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Select only subnets in allowed AZs
locals {
  allowed_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]

  filtered_subnets = [
    for s in data.aws_subnet.all_subnets :
    s.id if contains(local.allowed_azs, s.availability_zone)
  ]
}

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks" {
  name     = "authentik-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = slice(local.filtered_subnets, 0, 2) # Select at least 2 subnets
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

