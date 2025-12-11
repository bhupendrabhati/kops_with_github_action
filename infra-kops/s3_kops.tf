# S3 bucket used by kOps to store cluster state
resource "aws_s3_bucket" "kops_state" {
  bucket = "kops-state-${var.env}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "kops-state-${var.env}"
    Env  = var.env
  }
}

resource "aws_s3_bucket_acl" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
