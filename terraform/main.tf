provider "aws" {
    region  = "ap-northeast-1"
}

terraform {
  required_version = "~> 1.00"
  backend "local" {
    path = "terraform/terraform.tfstate"
  }
}

data "aws_caller_identity" "myself" {}
