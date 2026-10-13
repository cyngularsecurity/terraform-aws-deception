# Secrets Manager decoys — real-looking fake value

resource "random_id" "secret" {
  for_each    = local.secret_instances
  byte_length = 4
}

resource "random_password" "secret" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

resource "aws_secretsmanager_secret" "decoy" {
  for_each = local.secret_instances

  region                  = each.value.region
  name                    = "${var.secret.name_prefix}-${random_id.secret[each.key].hex}"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "decoy" {
  for_each = local.secret_instances

  region    = each.value.region
  secret_id = aws_secretsmanager_secret.decoy[each.key].id

  secret_string = jsonencode({
    username = "postgres"
    password = random_password.secret.result
    host     = "prod-db.us-east-1.rds.amazonaws.com"
    port     = 5432
    dbname   = "production"
  })
}
