# Attribution outputs: the platform stores these per-client and matches an
# observed touch back to the client by ARN/name without any in-account marker.

output "decoys" {
  description = "Created decoy attribution records. IAM access_key_id is non-secret; the secret access key is never output."
  value = {
    iam_users = { for k, v in aws_iam_user.decoy : k => {
      arn           = v.arn
      name          = v.name
      region        = "global"
      access_key_id = aws_iam_access_key.decoy[k].id
    } }
    iam_roles = { for k, v in aws_iam_role.decoy : k => {
      arn    = v.arn
      name   = v.name
      region = "global"
    } }
    s3_buckets = { for k, v in aws_s3_bucket.decoy : k => {
      arn    = v.arn
      name   = v.bucket
      region = local.s3_instances[k].region
    } }
    secrets = { for k, v in aws_secretsmanager_secret.decoy : k => {
      arn    = v.arn
      name   = v.name
      region = local.secret_instances[k].region
    } }
  }
}

output "tracking_tag" {
  description = "The tracking tag (key/value) applied to every decoy, echoed for the platform to register."
  value = {
    key   = var.tracking_tag_key
    value = var.tracking_tag_value
  }
}
