
locals {
  # Lure tags + tracking tag. No provider default_tags, no Cyngular string (cover).
  common_tags = merge(
    var.lure_tags,
    { (var.tracking_tag_key) = var.tracking_tag_value },
  )

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
