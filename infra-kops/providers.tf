terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

provider "aws" {
  region = var.aws_region
}
