terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tf_backend" {
  bucket = var.backend_bucket_name

  tags = {
    Name        = "${var.backend_bucket_name}"
    ManagedBy   = "github-actions-bootstrap"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_acl" "tf_backend" {
  bucket = aws_s3_bucket.tf_backend.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tf_backend" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_backend" {
  bucket = aws_s3_bucket.tf_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_backend.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamo_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.dynamo_table_name
    ManagedBy   = "github-actions-bootstrap"
    Environment = var.environment
  }
}
