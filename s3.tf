# S3 bucket decoys — BPA on, SSE-S3, read-reachable, mutation-guarded.

resource "random_id" "s3_bucket" {
  for_each    = local.s3_instances
  byte_length = 4
}

resource "aws_s3_bucket" "decoy" {
  for_each = local.s3_instances

  region        = each.value.region
  bucket        = "${var.s3_bucket.name_prefix}-${random_id.s3_bucket[each.key].hex}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "decoy" {
  for_each = local.s3_instances

  region = each.value.region
  bucket = aws_s3_bucket.decoy[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "decoy" {
  for_each = local.s3_instances

  region = each.value.region
  bucket = aws_s3_bucket.decoy[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "decoy" {
  for_each = local.s3_instances

  region       = each.value.region
  bucket       = aws_s3_bucket.decoy[each.key].id
  key          = "credentials.json"
  content_type = "application/json"
  content = jsonencode({
    db_host     = "prod-db.internal"
    db_user     = "admin"
    db_password = "Sup3rS3cur3P@ssw0rd!"
    db_name     = "production"
    db_port     = 5432
  })
  tags = local.common_tags
}

resource "aws_s3_bucket_policy" "guardrail" {
  for_each = local.s3_instances

  region = each.value.region
  bucket = aws_s3_bucket.decoy[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge({
        Sid       = "DenyBucketMutation"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucketPublicAccessBlock",
          "s3:PutBucket*",
          "s3:PutEncryptionConfiguration",
        ]
        Resource = aws_s3_bucket.decoy[each.key].arn
      }, local.guardrail_admin_exemption),
      merge({
        Sid       = "DenyObjectMutation"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:PutObject*",
          "s3:Replicate*",
          "s3:RestoreObject",
        ]
        Resource = "${aws_s3_bucket.decoy[each.key].arn}/*"
      }, local.guardrail_admin_exemption),
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.decoy[each.key].arn,
          "${aws_s3_bucket.decoy[each.key].arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.decoy,
    aws_s3_bucket_server_side_encryption_configuration.decoy,
    aws_s3_object.decoy,
  ]
}
