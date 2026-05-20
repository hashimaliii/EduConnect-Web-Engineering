variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "public_subnet_id" { type = string }
variable "private_subnet_id" { type = string }
variable "controller_sg_id" { type = string }
variable "agent_sg_id" { type = string }
variable "key_name" { type = string }
variable "environment" { type = string }