terraform {
  backend "s3" {
    bucket         = "educonnect-tf-state-2413ef29"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "educonnect-tf-locks"
    encrypt        = true
  }
}