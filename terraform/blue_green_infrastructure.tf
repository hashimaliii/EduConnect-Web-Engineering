# --- TASK 5: ECR Lifecycle Policy ---
resource "aws_ecr_lifecycle_policy" "educonnect_ecr_policy" {
  repository = aws_ecr_repository.educonnect_app.name
  policy     = <<EOF
{
    "rules": [
        { "rulePriority": 1, "description": "Expire untagged images older than 7 days", "selection": { "tagStatus": "untagged", "countType": "sinceImagePushed", "countUnit": "days", "countNumber": 7 }, "action": { "type": "expire" } },
        { "rulePriority": 2, "description": "Keep last 10 images", "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 10 }, "action": { "type": "expire" } }
    ]
}
EOF
}

# --- TASK 5: Jenkins Agent IAM Role ---
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role" "jenkins_agent_role" {
  name               = "jenkins-agent-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_admin" {
  role       = aws_iam_role.jenkins_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name = "jenkins-agent-profile"
  role = aws_iam_role.jenkins_agent_role.name
}
# IMPORTANT: You must add iam_instance_profile = aws_iam_instance_profile.jenkins_agent_profile.name to your existing Jenkins Agent EC2 resource.

# --- TASK 7: Application Load Balancer & Target Groups ---
resource "aws_lb" "app_alb" {
  name               = "educonnect-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # Requires 2 subnets
}

resource "aws_lb_target_group" "tg_blue" {
  name     = "tg-blue"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = "/health" }
}

resource "aws_lb_target_group" "tg_green" {
  name     = "tg-green"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = "/health" }
}

# Main Live Traffic Listener (Port 80) - Defaults to Blue
resource "aws_lb_listener" "live_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_blue.arn
  }
}

# Smoke Test Listener (Port 8080) - Defaults to Green
resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_green.arn
  }
}

# --- TASK 7: Launch Templates & Auto Scaling Groups ---
# Requires a separate IAM role for the application EC2 instances to pull from ECR
resource "aws_iam_instance_profile" "app_node_profile" {
  name = "app-node-profile"
  role = aws_iam_role.jenkins_agent_role.name # Reusing for simplicity, but best practice is a separate role
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "educonnect-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  iam_instance_profile { name = aws_iam_instance_profile.app_node_profile.name }
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # DYNAMIC USER DATA: Pulls specific tag stored in SSM or defaults to latest
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt-get update && sudo apt-get install -y docker.io awscli
    aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${aws_ecr_repository.educonnect_app.repository_url}
    # Fetch target image tag injected by Jenkins
    IMAGE_TAG=$(aws ssm get-parameter --name "/educonnect/deploy/target_tag" --query "Parameter.Value" --output text || echo "latest")
    sudo docker run -d -p 3000:3000 ${aws_ecr_repository.educonnect_app.repository_url}:$IMAGE_TAG
  EOF
  )
}

resource "aws_autoscaling_group" "asg_blue" {
  name                = "asg-blue"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id]
  min_size            = 1
  max_size            = 2
  target_group_arns   = [aws_lb_target_group.tg_blue.arn]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "asg_green" {
  name                = "asg-green"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id]
  min_size            = 1
  max_size            = 2
  target_group_arns   = [aws_lb_target_group.tg_green.arn]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}

# --- TASK 7: Deployment Log S3 Bucket ---
resource "aws_s3_bucket" "deployment_logs" {
  bucket = "educonnect-deployment-logs-${random_id.bucket_suffix.hex}"
}