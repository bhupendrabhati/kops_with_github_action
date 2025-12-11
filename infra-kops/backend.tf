  terraform {
    backend "s3" {
      bucket         = "::debug::exitcode: 0"
      key            = "kops/terraform.tfstate"
      region         = "ap-south-1"
      dynamodb_table = "::debug::exitcode: 0"
      encrypt        = true
    }
  }
