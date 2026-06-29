# Secrets Manager decoys — real-looking fake value, read-reachable,
# mutation-guarded.

resource "random_id" "secret" {
  for_each    = local.secret_instances
  byte_length = 4
}

resource "aws_secretsmanager_secret" "decoy" {
  for_each = local.secret_instances

  region                  = each.value.region
  name                    = "${var.secret.name_prefix}.${random_id.secret[each.key].hex}"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "decoy" {
  for_each = local.secret_instances

  region    = each.value.region
  secret_id = aws_secretsmanager_secret.decoy[each.key].id

  secret_string = jsonencode({
    username = "prod_admin"
    password = "Kx9#mP2$vL8nQ4wR"
    host     = "prod-db.us-east-1.rds.amazonaws.com"
    port     = 5432
    dbname   = "production"
  })
}

resource "aws_secretsmanager_secret_policy" "guardrail" {
  for_each = local.secret_instances

  region              = each.value.region
  secret_arn          = aws_secretsmanager_secret.decoy[each.key].arn
  block_public_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge({
        Sid       = "DenySecretMutation"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "secretsmanager:CancelRotateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:RemoveRegionsFromReplication",
          "secretsmanager:ReplicateSecretToRegions",
          "secretsmanager:RestoreSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:StopReplicationToReplica",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:UpdateSecret",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = aws_secretsmanager_secret.decoy[each.key].arn
      }, local.guardrail_admin_exemption),
      merge({
        Sid       = "DenySecretPolicyMutation"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "secretsmanager:DeleteResourcePolicy",
          "secretsmanager:PutResourcePolicy",
        ]
        Resource = aws_secretsmanager_secret.decoy[each.key].arn
      }, local.guardrail_admin_exemption),
    ]
  })

  depends_on = [aws_secretsmanager_secret_version.decoy]
}
