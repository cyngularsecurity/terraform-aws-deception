# terraform-aws-deception

Terraform module that plants **inert AWS decoy (honeytoken) resources** into a client account. Any interaction with a decoy is a high-signal detection: the resources are *meant* to be discoverable by an over-permissioned principal already in the account — that touch is the signal — while the resources themselves are inert and lead nowhere.

> **Status: scaffolding / in progress** (Track D.1, `DEVOPS-1329`). The input-variable and output **contract** (`variables.tf` / `outputs.tf`) is locked; the resource bodies (`main.tf`) are placeholders pending implementation of items 4–6.

## Design

- **Lure model — freely IAM-reachable, internet-unreachable.** Decoys are discoverable/touchable by any over-permissioned in-account principal (no deny-except-observer policies); they are never reachable from the public internet.
- **Identities are inert by policy, lured by name.** IAM user/role carry a flat `Deny *`; the IAM role additionally has an **empty trust policy** (cannot be assumed). The bait is the intriguing name (`admin`/`poweruser`-style) + believable lure tags. IAM user access keys are generated as bait.
- **No Cyngular reference anywhere in-account** — not in names, tags, descriptions, IAM paths, or provider default-tags (cover protection).
- **Attribution = created ARNs/names (outputs) + a caller-supplied tracking tag.** No observer principal, no steganographic marker.

## Resource kinds

| Kind | Scope | Posture |
|---|---|---|
| IAM user | global | flat `Deny *`, access keys generated (bait) |
| IAM role | global | empty trust policy + flat `Deny *` |
| S3 bucket | per-region | Block Public Access (all 4), SSE-S3, no restrictive policy, decoy objects |
| Secrets Manager secret | per-region | real-looking fake value, no restrictive resource policy |

## Usage

```hcl
module "deception" {
  source  = "cyngularsecurity/deception/aws"
  version = "x.y.z"

  regions            = ["us-east-1"]
  tracking_tag_key   = "cost-center"
  tracking_tag_value = "CC-9042"

  iam_user  = { enabled = true, count = 2, name_prefix = "svc-admin" }
  iam_role  = { enabled = true, count = 1, name_prefix = "poweruser" }
  s3_bucket = { enabled = true, count = 1, name_prefix = "legacy-backups" }
  secret    = { enabled = true, count = 1, name_prefix = "prod-db-credentials" }
}
```

See [`examples/basic`](examples/basic) for a runnable example.

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `regions` | Regions for regional kinds (S3, Secrets); IAM is global | `list(string)` | `["us-east-1"]` |
| `tracking_tag_key` | Attribution tag key (should mimic a normal client tag) | `string` | — (required) |
| `tracking_tag_value` | Attribution tag value | `string` | — (required) |
| `iam_user` / `iam_role` / `s3_bucket` / `secret` | Per-kind `{ enabled, count, name_prefix }` | `object` | `{}` (disabled) |
| `lure_tags` | Believable operational tags on every decoy | `map(string)` | `{ env = "prod", owner = "legacy-team" }` |

## Outputs

| Name | Description |
|---|---|
| `iam_user_arns` / `iam_role_arns` / `s3_bucket_arns` / `secret_arns` | Created ARNs per kind — the per-client attribution key |
| `tracking_tag` | The applied `{ key, value }`, echoed for platform registration |

## Out of scope

The UI form / quick-link generator (consumes the input contract) and the detection/alerting ingestion (consumes the outputs + tracking tag) are owned elsewhere. Org-level SCP is an optional manual prereq, not authored by this module.

## Releasing

Pushes to `main` trigger `.github/workflows/publish_tf_module.yml`, which auto-creates the next `vX.Y.Z` tag + GitHub release. The [Terraform Registry](https://registry.terraform.io) auto-publishes new tags once the repo is connected (one-time UI step). Requires a `PA_TOKEN` secret on the repo.
