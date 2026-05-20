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