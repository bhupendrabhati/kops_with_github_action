#!/usr/bin/env bash
# scripts/post_destroy_checklist.sh
# Safe, read-only checklist scanner that reports common leftover AWS resources after destroy.
# DOES NOT DELETE ANYTHING; purely diagnostic.
#
# Requirements: awscli (v2 recommended), jq
# Usage: ./scripts/post_destroy_checklist.sh [--profile PROFILE] [--region REGION] [--output-file FILE]
# Example: ./scripts/post_destroy_checklist.sh --region ap-south-1 --output-file /tmp/post_destroy_report.txt

set -euo pipefail

PROFILE=""
REGION=""
OUTFILE="/tmp/post_destroy_report.txt"

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="--profile $2"; shift 2;;
    --region) REGION="--region $2"; shift 2;;
    --output-file) OUTFILE="$2"; shift 2;;
    --help|-h) echo "Usage: $0 [--profile PROFILE] [--region REGION] [--output-file FILE]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

echo "Post-destroy checklist report" > "$OUTFILE"
echo "Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ") (UTC)" >> "$OUTFILE"
echo "" >> "$OUTFILE"

run_aws() {
  # wrapper to include profile/region if provided
  aws $* $PROFILE $REGION
}

section() {
  printf "\n===== %s =====\n\n" "$1" | tee -a "$OUTFILE"
}

# 1) Unattached EBS volumes (available)
section "Unattached EBS volumes (state=available)"
run_aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[*].{ID:VolumeId,Size:Size,AZ:AvailabilityZone,CreateTime:CreateTime,Tags:Tags}' --output json \
  | jq -r 'if (length == 0) then "No available (unattached) EBS volumes found." else (.[] | "ID: \(.ID)  Size: \(.Size)GiB  AZ: \(.AZ)  Created: \(.CreateTime)  Tags: \(.Tags|tostring)") end' \
  | tee -a "$OUTFILE"

# 2) Elastic IPs that are not associated
section "Elastic IPs (not associated)"
run_aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].{PublicIp:PublicIp,AllocationId:AllocationId,Domain:Domain,NetworkBorderGroup:NetworkBorderGroup}' --output json \
  | jq -r 'if (length == 0) then "No un-associated Elastic IPs found." else (.[] | "PublicIp: \(.PublicIp)  AllocationId: \(.AllocationId)  Domain: \(.Domain)  NBG: \(.NetworkBorderGroup)") end' \
  | tee -a "$OUTFILE"

# 3) NAT Gateways (any state other than deleted)
section "NAT Gateways (list)"
run_aws ec2 describe-nat-gateways \
  --query 'NatGateways[*].{NatId:NatGatewayId,State:State,Subnet:SubnetId,Vpc:VpcId,CreateTime:CreateTime}' --output json \
  | jq -r 'if (length == 0) then "No NAT Gateways found." else (.[] | "NatGatewayId: \(.NatId)  State: \(.State)  VPC: \(.Vpc)  Subnet: \(.Subnet)  Created: \(.CreateTime)") end' \
  | tee -a "$OUTFILE"

# 4) Load Balancers (ALB/NLB/CLB) - show all
section "Load Balancers (ELBv2)"
run_aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,Type:Type,State:State.Code,ARN:LoadBalancerArn,Scheme:Scheme}' --output json \
  | jq -r 'if (length == 0) then "No ELBv2 Load Balancers found." else (.[] | "Name: \(.Name)  Type: \(.Type)  State: \(.State)  Scheme: \(.Scheme)  ARN: \(.ARN)") end' \
  | tee -a "$OUTFILE"

# 5) Classic ELBs (if any)
section "Classic ELB (if used)"
run_aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].{Name:LoadBalancerName,DNSName:DNSName,Instances:Instances}' --output json \
  | jq -r 'if (length == 0) then "No Classic ELBs found." else (.[] | "Name: \(.Name)  DNS: \(.DNSName)  Instances: \(.Instances|length)") end' \
  | tee -a "$OUTFILE"

# 6) Network Interfaces (available/unattached)
section "Network interfaces (status=available / unattached)"
run_aws ec2 describe-network-interfaces --filters Name=status,Values=available \
  --query 'NetworkInterfaces[*].{ID:NetworkInterfaceId,Subnet:SubnetId,Vpc:VpcId,Description:Description}' --output json \
  | jq -r 'if (length == 0) then "No available (unattached) network interfaces found." else (.[] | "ID: \(.ID)  VPC: \(.Vpc)  Subnet: \(.Subnet)  Desc: \(.Description)") end' \
  | tee -a "$OUTFILE"

# 7) RDS instances (remaining)
section "RDS instances (remaining)"
run_aws rds describe-db-instances --query 'DBInstances[*].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine}' --output json \
  | jq -r 'if (length == 0) then "No RDS instances found." else (.[] | "ID: \(.Id)  Status: \(.Status)  Engine: \(.Engine)") end' \
  | tee -a "$OUTFILE"

# 8) EBS snapshots owned by this account
section "EBS snapshots (owned by self)"
ACCOUNT_ID=$(run_aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -n "$ACCOUNT_ID" ]; then
  run_aws ec2 describe-snapshots --owner-ids "$ACCOUNT_ID" --query 'Snapshots[*].{Id:SnapshotId,VolumeId:VolumeId,StartTime:StartTime,Description:Description}' --output json \
    | jq -r 'if (length == 0) then "No snapshots owned by this account found." else (.[] | "SnapshotId: \(.Id)  VolumeId: \(.VolumeId)  Created: \(.StartTime)  Desc: \(.Description)") end' \
    | tee -a "$OUTFILE"
else
  echo "Could not determine AWS Account ID; skipping snapshot listing." | tee -a "$OUTFILE"
fi

# 9) ECR repositories (leftover images)
section "ECR repositories (list)"
run_aws ecr describe-repositories --query 'repositories[*].{Name:repositoryName,URI:repositoryUri}' --output json \
  | jq -r 'if (length == 0) then "No ECR repositories found in this region/account." else (.[] | "Name: \(.Name)  URI: \(.URI)") end' \
  | tee -a "$OUTFILE"

# 10) CloudFormation stacks (leftover)
section "CloudFormation stacks (list)"
run_aws cloudformation describe-stacks --query 'Stacks[*].{Name:StackName,Status:StackStatus}' --output json \
  | jq -r 'if (length == 0) then "No CloudFormation stacks found." else (.[] | "Name: \(.Name)  Status: \(.Status)") end' \
  | tee -a "$OUTFILE"

echo "" >> "$OUTFILE"
echo "Report complete. Review above and delete any leftover resources manually if necessary." >> "$OUTFILE"

printf "\nReport written to %s\n" "$OUTFILE"
exit 0
