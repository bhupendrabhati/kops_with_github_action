output "backend_bucket" {
  value = aws_s3_bucket.tf_backend.id
  description = "S3 bucket created for terraform backend"
}

output "dynamo_table" {
  value = aws_dynamodb_table.tf_locks.name
  description = "DynamoDB table name used for terraform locking"
}
