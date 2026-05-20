variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "my_ip" {
  description = "Your personal public IP address for SSH access"
  type        = string
}