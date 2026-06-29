# terraform-aws-deception

This Terraform module plants inert AWS decoy (honeytoken) resources into a client account. Any interaction with a decoy is a high-signal detection: the resources are discoverable by an over-permissioned principal already in the account — that touch is the signal — while the resources themselves are inert and lead nowhere.

## Prerequisites

### Required Tools

- **Terraform >= 1.9, < 2.0**

  ```bash
  terraform --version
  ```

- **AWS CLI installed and authenticated**

  ```bash
  aws --version
  aws sts get-caller-identity
  ```

### AWS Permissions

The account deploying this module needs:

- `iam:CreateUser`, `iam:CreateRole`, `iam:PutUserPolicy`, `iam:PutRolePolicy`, `iam:CreateAccessKey`
- `s3:CreateBucket`, `s3:PutBucketPublicAccessBlock`, `s3:PutEncryptionConfiguration`, `s3:PutObject`, `s3:PutBucketPolicy`, `s3:DeleteBucketPolicy`
- `secretsmanager:CreateSecret`, `secretsmanager:PutSecretValue`, `secretsmanager:PutResourcePolicy`, `secretsmanager:DeleteResourcePolicy`

Verify your identity:

```bash
aws sts get-caller-identity
```

## How It Works

- **Lure model — read-reachable, internet-unreachable.** Decoys are discoverable and touchable by any over-permissioned in-account principal, while deny-only resource guardrails block using them as mutable infrastructure. They are never reachable from the public internet.
- **Identities are inert by policy, lured by name.** IAM users and roles carry a flat `Deny *` on all actions. The IAM role has a non-assumable trust policy. The bait is the intriguing name (`admin`/`poweruser`-style) combined with believable operational tags. IAM user access keys are generated as bait.
- **No vendor reference anywhere in-account.** Do not use vendor/deception/decoy strings in names, tags, descriptions, IAM paths, or provider default-tags.
- **Attribution via outputs + tracking tag.** The platform stores the created resource records and the caller-supplied tracking tag per client. No observer principal and no steganographic marker is placed in the account.

## Resource Kinds

| Kind | Scope | Posture |
|---|---|---|
| IAM user | Global | Flat `Deny *`, access keys generated as bait |
| IAM role | Global | Non-assumable trust policy + flat `Deny *` |
| S3 bucket | Per-region | Block Public Access (all 4 flags), SSE-S3, decoy object inside, deny-only mutation guardrail |
| Secrets Manager secret | Per-region | Real-looking fake value, deny-only mutation guardrail |

## Usage

### Minimal Configuration

```hcl
module "deception" {
  source  = "cyngularsecurity/deception/aws"

  tracking_tag_key   = "cost-center"
  tracking_tag_value = "CC-9042"

  iam_user = { enabled = true, count = 1, name_prefix = "svc-admin" }
}

output "decoys" {
  value = module.deception.decoys.iam_users
}
```

### Full Configuration (All Resource Kinds)

```hcl
module "deception" {
  source  = "cyngularsecurity/deception/aws"

  # Regions for S3 and Secrets Manager (IAM is global)
  regions = ["us-east-1"]

  # Attribution tag — should look like a normal client tag
  tracking_tag_key   = "cost-center"
  tracking_tag_value = "CC-9042"

  # Per-kind configuration
  iam_user  = { enabled = true, count = 2, name_prefix = "svc-admin" }
  iam_role  = { enabled = true, count = 1, name_prefix = "poweruser" }
  s3_bucket = { enabled = true, count = 1, name_prefix = "legacy-backups" }
  secret    = { enabled = true, count = 1, name_prefix = "prod-db-credentials" }

  # Optional additional exemptions. The current Terraform caller is exempted
  # automatically so it can maintain/destroy guarded resources.
  guardrail_admin_principal_arns = [
    "arn:aws:iam::123456789012:role/TerraformAdmin",
    "arn:aws:sts::123456789012:assumed-role/TerraformAdmin/*",
  ]

  # Operational lure tags applied to every decoy resource
  lure_tags = {
    env   = "prod"
    owner = "legacy-team"
  }
}

output "decoys" {
  value = module.deception.decoys
}

output "tracking_tag" {
  value = module.deception.tracking_tag
}
```

See [`examples/basic`](examples/basic) for a runnable example.

## Variables

| Name | Required | Default | Description |
|---|---|---|---|
| `tracking_tag_key` | Yes | — | Tag key applied to every decoy resource for attribution. Should look like a normal client tag. |
| `tracking_tag_value` | Yes | — | Tag value applied to every decoy resource for attribution. |
| `regions` | No | `["us-east-1"]` | Regions for regional resource kinds (S3, Secrets Manager). IAM is global and ignores this. |
| `guardrail_admin_principal_arns` | No | `[]` | Additional client IAM principal ARN patterns exempt from deny-only resource guardrails for maintenance. Current Terraform caller is exempt automatically. |
| `iam_user` | No | `{}` (disabled) | IAM user honeytokens. `{ enabled, count, name_prefix }` |
| `iam_role` | No | `{}` (disabled) | IAM role honeytokens. `{ enabled, count, name_prefix }` |
| `s3_bucket` | No | `{}` (disabled) | S3 bucket decoys. `{ enabled, count, name_prefix }` |
| `secret` | No | `{}` (disabled) | Secrets Manager decoys. `{ enabled, count, name_prefix }` |
| `lure_tags` | No | `{ env = "prod", owner = "legacy-team" }` | Believable operational tags applied to every decoy resource. |

## Outputs

| Name | Description |
|---|---|
| `decoys` | Concise attribution records: ARN, name, region, and IAM user access key ID only |
| `tracking_tag` | The applied `{ key, value }` tracking tag, echoed for platform registration |

## Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply

```bash
terraform apply
```

Type `yes` to confirm.

### 4. Retrieve Outputs

```bash
terraform output
terraform output decoys
terraform output tracking_tag
```


## Project Structure

```
terraform-aws-deception/
├── examples/
│   └── basic/           # Runnable example configuration
├── .github/
│   └── workflows/
│       └── publish_tf_module.yml  # Auto-tag and release on push to main
├── .gitignore
├── README.md
├── versions.tf          # Terraform and provider version constraints
├── data.tf              # Caller identity used for guardrail maintenance exemptions
├── variables.tf         # Module input variables
├── locals.tf            # Common tags and per-kind instance maps
├── iam.tf               # IAM users (+ access keys) and IAM roles
├── s3.tf                # S3 buckets, BPA, SSE, decoy objects
├── secrets.tf           # Secrets Manager secrets and versions
├── outputs.tf           # Module outputs (decoy records + tracking tag)
└── main.tf              # Module header and design notes
```

## Cleanup

To destroy all decoy resources:

```bash
terraform destroy
```

## Troubleshooting

### `InvalidClientTokenId` or `AuthFailure`

Your AWS credentials are not configured or have expired. Re-authenticate:

```bash
aws sso login
# or
aws configure
```

### `AccessDenied` on IAM or S3 resources

The deploying principal lacks the required permissions. Verify the permissions listed in the [Prerequisites](#prerequisites) section or contact your AWS administrator.

### Secrets Manager deletion delay

Secrets Manager enforces a recovery window by default. This module sets `recovery_window_in_days = 0` to allow immediate deletion on `terraform destroy`. If you see a conflict on re-deploy with the same name, wait a moment and retry.

## Releasing

Pushes to `main` trigger `.github/workflows/publish_tf_module.yml`, which auto-creates the next `vX.Y.Z` tag and GitHub release. The [Terraform Registry](https://registry.terraform.io) auto-publishes new tags once the repo is connected (one-time UI step).
