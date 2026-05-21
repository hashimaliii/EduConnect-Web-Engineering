terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  my_ip       = var.my_ip
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.environment}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.environment}-key.pem"
  file_permission = "0400" # Strict permissions required by SSH
}

resource "aws_ecr_repository" "educonnect_app" {
  name                 = "educonnect-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_ami" "custom_ubuntu" {
  most_recent = true
  owners      = ["self"] # Tells AWS to look at YOUR account, not Canonical's

  filter {
    name   = "name"
    values = ["educonnect-custom-ami-*"]
  }
}

module "web_server" {
  source = "./modules/compute"

  ami_id             = data.aws_ami.custom_ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.web_sg_id]
  key_name           = aws_key_pair.generated_key.key_name
  environment        = var.environment
  server_name        = "web-server"

  user_data_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install nginx -y
    systemctl start nginx
    systemctl enable nginx
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "<h1>Welcome to EduConnect Web Server</h1><p>Instance ID: $INSTANCE_ID</p>" > /var/www/html/index.html
  EOF
}

module "db_server" {
  source = "./modules/compute"

  ami_id             = data.aws_ami.custom_ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.private_subnet_ids[0]
  security_group_ids = [module.security.db_sg_id]
  key_name           = aws_key_pair.generated_key.key_name
  environment        = var.environment
  server_name        = "db-server"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "jenkins" {
  source = "./modules/jenkins"

  # We use the standard Canonical Ubuntu AMI for Jenkins, NOT our custom Packer image
  ami_id = data.aws_ami.ubuntu.id

  # Jenkins requires more memory. t3.micro will crash running Java + Docker.
  instance_type = "t3.small"

  public_subnet_id  = module.vpc.public_subnet_ids[0]
  private_subnet_id = module.vpc.private_subnet_ids[0]
  controller_sg_id  = module.security.jenkins_controller_sg_id
  agent_sg_id       = module.security.jenkins_agent_sg_id
  key_name          = aws_key_pair.generated_key.key_name
  environment       = var.environment
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Allow Kubernetes API and Web Traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH access
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins needs access to the K8s API
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Public internet access to your app
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_cluster" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small" 
  key_name      = aws_key_pair.jenkins_key.key_name
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  # This 1-liner installs Kubernetes automatically on boot
  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | sh -
    sleep 15
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
  EOF

  tags = {
    Name = "EduConnect-K8s-Cluster"
  }
}

output "k8s_public_ip" {
  value = aws_instance.k8s_cluster.public_ip
}