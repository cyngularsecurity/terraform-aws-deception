# Secrets Manager decoys — real-looking fake value, no restrictive
# resource policy.

resource "random_id" "secret" {
  for_each    = local.secret_instances
  byte_length = 4
}

resource "aws_secretsmanager_secret" "decoy" {
  for_each = local.secret_instances

  name                    = "${var.secret.name_prefix}-${random_id.secret[each.key].hex}"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "decoy" {
  for_each = local.secret_instances

  secret_id = aws_secretsmanager_secret.decoy[each.key].id

  secret_string = jsonencode({
    username = "prod_admin"
    password = "Kx9#mP2$vL8nQ4wR"
    host     = "prod-db.us-east-1.rds.amazonaws.com"
    port     = 5432
    dbname   = "production"
  })
}
