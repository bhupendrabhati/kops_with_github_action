output "backend_bucket" {
  value = aws_s3_bucket.tf_backend.id
}

output "dynamo_table" {
  value = aws_dynamodb_table.tf_locks.name
}
