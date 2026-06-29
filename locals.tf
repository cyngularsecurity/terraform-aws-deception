
locals {
  # Lure tags + tracking tag. No provider default_tags, no Cyngular string (cover).
  common_tags = merge(
    var.lure_tags,
    { (var.tracking_tag_key) = var.tracking_tag_value },
  )

  current_assumed_role_matches = regexall("^arn:[^:]+:sts::[0-9]+:assumed-role/([^/]+)/.*$", data.aws_caller_identity.current.arn)
  current_assumed_role_name    = length(local.current_assumed_role_matches) > 0 ? local.current_assumed_role_matches[0][0] : null

  current_guardrail_admin_principal_arns = concat(
    [data.aws_caller_identity.current.arn],
    local.current_assumed_role_name == null ? [] : [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.current_assumed_role_name}",
      "arn:${data.aws_partition.current.partition}:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${local.current_assumed_role_name}/*",
    ],
  )

  guardrail_admin_principal_arns = distinct(concat(
    local.current_guardrail_admin_principal_arns,
    var.guardrail_admin_principal_arns,
  ))

  guardrail_admin_exemption = {
    Condition = {
      ArnNotLike = {
        "aws:PrincipalArn" = local.guardrail_admin_principal_arns
      }
    }
  }

  iam_user_instances = var.iam_user.enabled ? {
    for i in range(var.iam_user.count) : tostring(i) => i
  } : {}

  iam_role_instances = var.iam_role.enabled ? {
    for i in range(var.iam_role.count) : tostring(i) => i
  } : {}

  # S3 and Secrets fan out over regions × count; each instance carries its region.
  s3_instances = var.s3_bucket.enabled ? {
    for pair in setproduct(toset(var.regions), range(var.s3_bucket.count)) :
    "${pair[0]}-${pair[1]}" => { region = tostring(pair[0]), index = tonumber(pair[1]) }
  } : {}

  secret_instances = var.secret.enabled ? {
    for pair in setproduct(toset(var.regions), range(var.secret.count)) :
    "${pair[0]}-${pair[1]}" => { region = tostring(pair[0]), index = tonumber(pair[1]) }
  } : {}
}
