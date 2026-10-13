output "iam_user_arns" {
  description = "ARNs of the created IAM user honeytokens, keyed by instance."
  value       = { for k, v in aws_iam_user.decoy : k => v.arn }
}

output "iam_role_arns" {
  description = "ARNs of the created IAM role honeytokens, keyed by instance."
  value       = { for k, v in aws_iam_role.decoy : k => v.arn }
}

output "s3_bucket_arns" {
  description = "ARNs of the created S3 bucket decoys, keyed by instance."
  value       = { for k, v in aws_s3_bucket.decoy : k => v.arn }
}

output "secret_arns" {
  description = "ARNs of the created Secrets Manager decoys, keyed by instance."
  value       = { for k, v in aws_secretsmanager_secret.decoy : k => v.arn }
}

output "tracking_tag" {
  description = "The tracking tag (key/value) applied to every decoy, echoed for the platform to register."
  value = {
    key   = var.tracking_tag_key
    value = var.tracking_tag_value
  }
}

output "decoy_scripts_bucket_arns" {
  description = "ARNs of the decoy DevOps-scripts buckets, keyed by region."
  value       = { for r, b in aws_s3_bucket.scripts : r => b.arn }
}

output "decoy_scripts_object_paths" {
  description = "Planted script object keys (the same set exists in every regional scripts bucket)."
  value       = [for f in local.scripts_selected : local.script_paths[f]]
}
