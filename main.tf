# =============================================================================
# terraform-aws-deception
# Client-run module that plants inert AWS decoy resources.
#
# Design (Track D.1, locked 2026-06-04):
#   - Resources are freely IAM-reachable but internet-unreachable; the touch
#     is the signal.
#   - Identities are inert by policy (flat Deny *); IAM role additionally has
#     an empty trust policy (not assumable).
#   - Nothing in-account references Cyngular (names, tags, descriptions,
#     paths, provider default-tags).
#   - Attribution = created ARNs/names (outputs) + a caller-supplied tracking
#     tag. No observer principal, no steganographic marker.
#
# NOTE: resource bodies below are SCAFFOLDING placeholders — the contract
# (variables.tf / outputs.tf) is the locked surface; implementations land per
# items 4-6 (DEVOPS-1329).
# =============================================================================

locals {
  # Common tags = lure tags + the caller-supplied tracking tag.
  # Deliberately NO default_tags on the provider and NO Cyngular string.
  common_tags = merge(
    var.lure_tags,
    { (var.tracking_tag_key) = var.tracking_tag_value },
  )
}

# ---------------------------------------------------------------------------
# IAM user honeytokens (item 5) — flat Deny *, access keys as bait.
# resource "aws_iam_user" "decoy" { ... }
# resource "aws_iam_user_policy" "deny_all" { ... }
# resource "aws_iam_access_key" "decoy" { ... }

# ---------------------------------------------------------------------------
# IAM role honeytokens (item 5) — empty trust policy + flat Deny *.
# resource "aws_iam_role" "decoy" { ... }
# resource "aws_iam_role_policy" "deny_all" { ... }

# ---------------------------------------------------------------------------
# S3 bucket decoys (item 6) — BPA on, no restrictive policy, decoy objects.
# resource "aws_s3_bucket" "decoy" { ... }
# resource "aws_s3_bucket_public_access_block" "decoy" { ... }

# ---------------------------------------------------------------------------
# Secrets Manager decoys (item 6) — real-looking fake value, not public.
# resource "aws_secretsmanager_secret" "decoy" { ... }
# resource "aws_secretsmanager_secret_version" "decoy" { ... }
