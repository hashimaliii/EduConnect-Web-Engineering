variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "The instance_type must be one of: t3.micro, t3.small, t3.medium."
  }
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "server_name" {
  type        = string
  description = "Used to tag the specific server (e.g., web or db)"
}

variable "user_data_script" {
  type    = string
  default = null # Only the web server needs this; the DB server will pass null
}