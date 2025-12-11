  terraform {
    backend "s3" {
      bucket         = "kops-bucket-bhupen"
      key            = "kops/terraform.tfstate"
      region         = "ap-south-1"
      dynamodb_table = "terraform-locks"
      encrypt        = true
    }
  }
