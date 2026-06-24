# S3 bucket decoys — BPA on, SSE-S3, no restrictive bucket policy,
# decoy object inside.

resource "random_id" "s3_bucket" {
  for_each    = local.s3_instances
  byte_length = 4
}

resource "aws_s3_bucket" "decoy" {
  for_each = local.s3_instances

  bucket        = "${var.s3_bucket.name_prefix}-${random_id.s3_bucket[each.key].hex}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "decoy" {
  for_each = local.s3_instances

  bucket = aws_s3_bucket.decoy[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "decoy" {
  for_each = local.s3_instances

  bucket = aws_s3_bucket.decoy[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "decoy" {
  for_each = local.s3_instances

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
