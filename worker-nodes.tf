resource "aws_iam_role" "node_group_role" {
  name = "authentik-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "authentik-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = ["subnet-00c15e508f4bffe2a", "subnet-094f6fb2e37b2c508"]  # Updated with valid subnet IDs

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  launch_template {
    id      = aws_launch_template.custom_ami.id
    version = "$Latest"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_launch_template" "custom_ami" {
  name_prefix   = "authentik-launch-template"
  image_id      = "ami-04b4f1a9cf54c11d0"  # Your custom AMI ID
  instance_type = "t2.medium"

  network_interfaces {
    security_groups = ["sg-035005143db74db35"]  # Updated with your security group ID
  }

  lifecycle {
    create_before_destroy = true
  }
}

