# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Change to your desired region
}

# Data source for the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical's AWS account ID
}

# Create a Key Pair for SSH access
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-ssh-key" # Change to your key name
  public_key = file("~/.ssh/id_rsa.pub") # Path to your public key
}

# Security Group for the master node
resource "aws_security_group" "k8s_sg" {
  name        = "kubernetes-master-sg"
  description = "Allow traffic for Kubernetes cluster"
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443 # Kube API Server port
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All traffic within the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  # Egress (outbound) rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kubernetes Master Node EC2 Instance
resource "aws_instance" "k8s_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium" # Minimum recommended for Kubeadm master
  key_name      = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  
  # Inject the shell script to bootstrap Kubernetes
  user_data = file("master_bootstrap.sh")

  tags = {
    Name = "k8s-Master-Node"
  }
}

# Output the master node's public IP
output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}