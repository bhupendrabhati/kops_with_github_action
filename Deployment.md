# DEPLOYMENT — infra-kops (GitHub Actions automation)

This document describes the CI/CD lifecycle used by this repository and how to safely bootstrap, deploy, and fully destroy resources. It also explains how to use the post-destroy checklist to verify AWS is clean.

---

## Workflows overview

`.github/workflows/` contains:

- `bootstrap-backend.yml` — create S3 backend + DynamoDB for Terraform remote state (run once).
- `infra-and-kops.yml` — main pipeline:
  - **PR**: runs `terraform plan` (upload plan artifact).
  - **Merge to `main`**: runs `terraform apply`, `kops` create/update, and deploys manifests.
  - Ignores changes when only `.github/workflows/**` files change.
- `destroy.yml` — manual, safe destroy. Requires `confirm = YES`.
- After `destroy` the pipeline runs `scripts/post_destroy_checklist.sh` and uploads a `post-destroy-report` artifact.

---

## Setup (one-time)

1. Add GitHub repository secrets (Settings → Secrets & variables → Actions):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., `ap-south-1`)
   - `KOPS_SSH_PUBLIC_KEY` (recommended)
   - Optionally: `CLUSTER_NAME`

2. Ensure the following files exist in repo:
   - `infra-bootstrap/` (bootstrap terraform)
   - `infra-kops/` (main terraform + cluster.yaml and manifests)
   - `.github/workflows/bootstrap-backend.yml`
   - `.github/workflows/infra-and-kops.yml`
   - `.github/workflows/destroy.yml`

3. Run the bootstrap workflow (Actions → Bootstrap Terraform Backend → Run workflow)
   - Provide a **globally unique** S3 bucket name (e.g., `my-org-terraform-state-<yourid>`).
   - The workflow will create S3 + DynamoDB and attempt to commit `infra-kops/backend.tf`.

---

## Daily developer flow (PR → merge)

1. Make changes in a branch and open a Pull Request to `main`.
   - The PR will trigger `terraform plan`. Inspect the plan in the Actions run (download `tfplan.json` if needed).
2. After review, merge the PR to `main` (recommended: protected branch with required reviewers).
   - On merge, `terraform apply` runs (on `main`) and the pipeline will update kops cluster and deploy manifests.

---

## Destroy (fully remove resources)

1. Go to Actions → Destroy infra and kOps cluster → Run workflow.
2. Set `confirm = YES`. Optionally set `destroy_bootstrap = YES` to also remove S3 backend and DynamoDB created by bootstrap.
3. After job completion download the artifact `post-destroy-report` from the workflow run. It contains a checklist of likely leftover resources.

---

## Interpreting the post-destroy report

The report (artifact `post-destroy-report`) lists:

- Unattached EBS volumes (state=available)
- Unassociated Elastic IPs
- NAT Gateways
- Load Balancers (ALB/NLB/CLB)
- Unattached network interfaces
- RDS instances
- EBS snapshots owned by the account
- ECR repositories
- CloudFormation stacks

**Action**: for each leftover resource listed, review in the AWS Console and delete if not needed. Key expensive items to check first:
- NAT Gateways (costly)
- Elastic IPs (when allocated)
- EBS volumes and snapshots
- Load Balancers and active ENIs
- RDS instances

---

## How to add screenshots to this doc

If you'd like `DEPLOYMENT.md` to include screenshots:
1. Take screenshots of relevant Action run logs (Actions → choose run → open logs).
2. Save images into `docs/images/` in repo.
3. Reference them in this file with Markdown:
   ```md
   ![Plan artifact view](docs/images/plan-artifact.png)
