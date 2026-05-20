packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# 1. The Base Image
source "amazon-ebs" "ubuntu" {
  ami_name      = "educonnect-custom-ami-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  ssh_username  = "ubuntu"

  # Find the official Ubuntu 22.04 base
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

# 2. The Build Instructions
build {
  name    = "educonnect-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # Inject the software before taking the snapshot
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to unlock apt...'",
      "sleep 30", 
      "sudo apt-get update -y",
      "sudo apt-get install nginx curl -y",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "echo '<h1>Welcome to EduConnect (Custom Packer AMI)</h1>' | sudo tee /var/www/html/index.html"
    ]
  }
}