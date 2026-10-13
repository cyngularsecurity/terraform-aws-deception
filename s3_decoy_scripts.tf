resource "aws_s3_bucket" "scripts" {
  for_each = var.decoy_scripts.enabled ? toset(var.regions) : toset([])

  region        = each.key
  bucket        = "${var.decoy_scripts.name_prefix}-${random_id.scripts_suffix[0].hex}-${each.key}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  for_each = aws_s3_bucket.scripts

  region = each.key
  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  for_each = aws_s3_bucket.scripts

  region = each.key
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "script" {
  for_each = local.script_object_instances

  region       = each.value.region
  bucket       = aws_s3_bucket.scripts[each.value.region].id
  key          = local.script_paths[each.value.script]
  content_type = "text/x-python"
  content = templatefile("${path.module}/templates/scripts/${each.value.script}", {
    credentials = local.script_credentials[each.value.script]
  })
  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.decoy_scripts.token_type != "iam_user_key" || (var.iam_user.enabled && var.iam_user.count > 0)
      error_message = "decoy_scripts.token_type = iam_user_key requires iam_user.enabled = true and count > 0 (the script embeds the module's inert IAM user access key)."
    }
  }
}
