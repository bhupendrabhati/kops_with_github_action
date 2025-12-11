# resource "null_resource" "kops_create_cluster" {
#   provisioner "local-exec" {
#     command = <<EOT
# export AWS_ACCESS_KEY_ID=${aws_iam_access_key.kops_user_key.id}
# export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.kops_user_key.secret}
# export KOPS_STATE_STORE=s3://${aws_s3_bucket.kops_state.bucket}
# kops create cluster --name=${var.cluster_name} --state ${KOPS_STATE_STORE} --zones ${var.aws_region}a,${var.aws_region}b --node-count=${var.node_count} --node-size=${var.node_size} --master-size=${var.master_size} --yes
# EOT
#     interpreter = ["/bin/bash","-c"]
#   }
#   depends_on = [aws_s3_bucket.kops_state, aws_iam_access_key.kops_user_key]
# }
