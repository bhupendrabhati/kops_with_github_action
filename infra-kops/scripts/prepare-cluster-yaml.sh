#!/bin/bash
# Script to prepare cluster.yml by substituting environment variables
# Usage: ./scripts/prepare-cluster-yaml.sh
#
# Required environment variables:
#   - CLUSTER_NAME: kOps cluster name (e.g., my-idp.k8s.local)
#   - KOPS_STATE_STORE: S3 bucket path (e.g., s3://kops-state-dev-abc123)

set -euo pipefail

if [ -z "${CLUSTER_NAME:-}" ]; then
  echo "ERROR: CLUSTER_NAME environment variable not set"
  exit 1
fi

if [ -z "${KOPS_STATE_STORE:-}" ]; then
  echo "ERROR: KOPS_STATE_STORE environment variable not set"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLUSTER_YAML_TEMPLATE="$REPO_DIR/infra-kops/cluster.yml"
CLUSTER_YAML_OUT="$REPO_DIR/infra-kops/cluster-prepared.yml"

echo "Preparing cluster.yml..."
echo "  CLUSTER_NAME: $CLUSTER_NAME"
echo "  KOPS_STATE_STORE: $KOPS_STATE_STORE"

# Substitute variables in cluster.yml template
envsubst < "$CLUSTER_YAML_TEMPLATE" > "$CLUSTER_YAML_OUT"

echo "✓ Generated: $CLUSTER_YAML_OUT"
echo ""
echo "Next steps:"
echo "  1. Review the generated file: cat $CLUSTER_YAML_OUT"
echo "  2. Use with kops: kops replace -f $CLUSTER_YAML_OUT --state=\$KOPS_STATE_STORE"
