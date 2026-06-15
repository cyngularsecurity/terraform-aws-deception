# =============================================================================
# Attribution outputs (Track D.1, items 3 + 10)
# The platform stores these per-client and matches an observed touch back to
# the client by ARN. This is the primary attribution key — zero in-account
# marker. Placeholders until the resources land (items 4-6).
# =============================================================================

output "iam_user_arns" {
  description = "ARNs of the created IAM user honeytokens, keyed by instance."
  value       = {} # for_each = aws_iam_user.decoy : k => v.arn
}

output "iam_role_arns" {
  description = "ARNs of the created IAM role honeytokens, keyed by instance."
  value       = {}
}

output "s3_bucket_arns" {
  description = "ARNs of the created S3 bucket decoys, keyed by instance."
  value       = {}
}

output "secret_arns" {
  description = "ARNs of the created Secrets Manager decoys, keyed by instance."
  value       = {}
}

output "tracking_tag" {
  description = "The tracking tag (key/value) applied to every decoy, echoed for the platform to register."
  value = {
    key   = var.tracking_tag_key
    value = var.tracking_tag_value
  }
}
