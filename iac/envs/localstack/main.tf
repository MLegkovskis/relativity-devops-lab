resource "aws_vpc" "eks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "bh-local-vpc"
  }
}

resource "aws_subnet" "eks" {
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "bh-local-subnet"
  }
}

resource "aws_eks_cluster" "this" {
  name     = "bh-local"
  role_arn = "arn:aws:iam::000000000000:role/eks-role"
  version  = "1.19"

  vpc_config {
    subnet_ids = [aws_subnet.eks.id]
  }
}

resource "null_resource" "kubeconfig" {
  depends_on = [aws_eks_cluster.this]

  provisioner "local-exec" {
    command = "awslocal eks update-kubeconfig --name bh-local --region ${var.region}"
  }
}

resource "kubernetes_namespace" "blackhole" {
  depends_on = [null_resource.kubeconfig]

  metadata {
    name = "blackhole"
  }
}
