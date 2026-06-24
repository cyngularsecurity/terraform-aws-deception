# IAM user honeytokens — flat Deny *, access keys as bait.

resource "random_id" "iam_user" {
  for_each    = local.iam_user_instances
  byte_length = 4
}

resource "aws_iam_user" "decoy" {
  for_each = local.iam_user_instances

  name = "${var.iam_user.name_prefix}-${random_id.iam_user[each.key].hex}"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "deny_all" {
  for_each = local.iam_user_instances

  name = "deny-all"
  user = aws_iam_user.decoy[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_access_key" "decoy" {
  for_each = local.iam_user_instances

  user = aws_iam_user.decoy[each.key].name
}

# IAM role honeytokens — empty trust policy + flat Deny *.

resource "random_id" "iam_role" {
  for_each    = local.iam_role_instances
  byte_length = 4
}

resource "aws_iam_role" "decoy" {
  for_each = local.iam_role_instances

  name = "${var.iam_role.name_prefix}-${random_id.iam_role[each.key].hex}"

  # Non-existent account — trust policy is valid but nobody can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Principal = {
        AWS = "*"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "deny_all" {
  for_each = local.iam_role_instances

  name = "deny-all"
  role = aws_iam_role.decoy[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
    }]
  })
}
