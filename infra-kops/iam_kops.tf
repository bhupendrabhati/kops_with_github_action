resource "aws_iam_user" "kops_user" {
  name = "kops-user-${var.env}"
}

resource "aws_iam_access_key" "kops_user_key" {
  user = aws_iam_user.kops_user.name
}

# Minimal-ish policy for kOps operations (adjust ARNs for production)
resource "aws_iam_policy" "kops_policy" {
  name        = "kops-policy-${var.env}"
  description = "Least-privilege-ish policy for kOps demo (tune for production)"

  policy = file("${path.module}/policies/kops_iam_policy.json")
}

resource "aws_iam_user_policy_attachment" "kops_attach_policy" {
  user       = aws_iam_user.kops_user.name
  policy_arn = aws_iam_policy.kops_policy.arn
}

output "kops_aws_access_key_id" {
  value       = aws_iam_access_key.kops_user_key.id
  description = "AWS Access Key ID for the kOps IAM user"
}

output "kops_aws_secret_access_key" {
  value       = aws_iam_access_key.kops_user_key.secret
  description = "AWS Secret Access Key for the kOps IAM user (sensitive)"
  sensitive   = true
}

output "kops_state_bucket" {
  value = aws_s3_bucket.kops_state.bucket
}
