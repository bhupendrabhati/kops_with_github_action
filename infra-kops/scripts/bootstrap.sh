#!/bin/bash
# helper script: set env vars from terraform outputs file
if [ ! -f tf_outputs.json ]; then
  echo "Place tf_outputs.json (terraform output -json) in this directory"
  exit 1
fi
KOPS_STATE_STORE=$(jq -r .kops_state_bucket.value tf_outputs.json)
AWS_ACCESS_KEY_ID=$(jq -r .kops_aws_access_key_id.value tf_outputs.json)
AWS_SECRET_ACCESS_KEY=$(jq -r .kops_aws_secret_access_key.value tf_outputs.json)
export KOPS_STATE_STORE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION=ap-south-1

echo "Environment variables set. KOPS_STATE_STORE=${KOPS_STATE_STORE}"
