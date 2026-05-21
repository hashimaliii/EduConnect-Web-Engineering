resource "aws_instance" "jenkins_controller" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.controller_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    
    # Fix: Install Java 21 (Jenkins newly enforced requirement)
    sudo apt-get install openjdk-21-jre -y
    
    # Fix: Use the new 2026 GPG key
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    # Install Git, Docker, Unzip
    sudo apt-get install git docker.io unzip -y
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker jenkins

    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Install Terraform
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update
    sudo apt-get install terraform -y
  EOF

  tags = {
    Name = "${var.environment}-jenkins-controller"
  }
}

# The specific permissions policy
data "aws_iam_policy_document" "jenkins_ecr_policy" {
  statement {
    sid    = "AllowECRAuthAndPush"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"] # GetAuthorizationToken requires *, strictly speaking
  }
}


# Trust Policy allowing EC2 to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_agent_role" {
  name               = "jenkins-agent-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "jenkins_ecr_attachment" {
  name   = "jenkins-ecr-permissions"
  role   = aws_iam_role.jenkins_agent_role.id
  policy = data.aws_iam_policy_document.jenkins_ecr_policy.json
}

# 3. The Instance Profile to attach to the EC2 server
resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name = "jenkins-agent-profile"
  role = aws_iam_role.jenkins_agent_role.name
}

resource "aws_instance" "jenkins_agent" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.agent_sg_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_agent_profile.name

  # The agent needs Java and Docker to execute pipelines
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    
    # Install Java, Git, Docker
    sudo apt-get install openjdk-21-jre git docker.io -y
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
    
    # Install Node.js & NPM
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
  EOF

  tags = {
    Name = "${var.environment}-jenkins-agent"
  }
}