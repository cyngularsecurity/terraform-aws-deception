# Decoy DevOps scripts — a "devops-scripts" bucket of realistic Python scripts, each carrying an embedded honeytoken

data "aws_caller_identity" "current" {}

locals {
  scripts_account = data.aws_caller_identity.current.account_id

  script_templates = var.decoy_scripts.enabled ? fileset("${path.module}/templates/scripts", "*.py.tftpl") : toset([])

  scripts_selected = slice(
    [for pair in sort([for f in local.script_templates : "${md5("${local.scripts_account}-${var.decoy_scripts.name_prefix}-${f}")}|${f}"]) : split("|", pair)[1]],
    0,
    min(var.decoy_scripts.script_count, length(local.script_templates)),
  )

  script_path_prefixes = ["", "ci/", "tools/", "scripts/deploy/", "internal/jobs/"]
  script_path_hash     = { for f in local.scripts_selected : f => parseint(substr(md5("${local.scripts_account}-${f}"), 0, 6), 16) }
  script_paths = {
    for f in local.scripts_selected : f =>
    "${local.script_path_prefixes[local.script_path_hash[f] % length(local.script_path_prefixes)]}${trimsuffix(f, ".tftpl")}"
  }

  _iam_user_list = sort(keys(local.iam_user_instances))
  script_iam_user = var.decoy_scripts.token_type == "iam_user_key" && length(local._iam_user_list) > 0 ? {
    for i, f in local.scripts_selected : f => local._iam_user_list[i % length(local._iam_user_list)]
  } : {}

  script_credentials = {
    for f in local.scripts_selected : f => {
      gitlab       = "GITLAB_TOKEN = \"glpat-${try(random_string.script_token[f].result, "")}\""
      aws          = "AWS_ACCESS_KEY_ID = \"AKIA${try(random_string.script_token[f].result, "")}\"\nAWS_SECRET_ACCESS_KEY = \"${try(random_password.script_secret[f].result, "")}\""
      iam_user_key = "AWS_ACCESS_KEY_ID = \"${try(aws_iam_access_key.decoy[local.script_iam_user[f]].id, "")}\"\nAWS_SECRET_ACCESS_KEY = \"${try(aws_iam_access_key.decoy[local.script_iam_user[f]].secret, "")}\""
    }[var.decoy_scripts.token_type]
  }

  script_object_instances = {
    for pair in setproduct(tolist(var.regions), local.scripts_selected) :
    "${pair[0]}::${pair[1]}" => { region = pair[0], script = pair[1] }
  }
}

resource "random_id" "scripts_suffix" {
  count       = var.decoy_scripts.enabled ? 1 : 0
  byte_length = 2
  keepers = {
    name_prefix = var.decoy_scripts.name_prefix
    account_id  = local.scripts_account
  }
}

resource "random_string" "script_token" {
  for_each = contains(["gitlab", "aws"], var.decoy_scripts.token_type) ? toset(local.scripts_selected) : toset([])

  length  = var.decoy_scripts.token_type == "aws" ? 16 : 20
  upper   = true
  lower   = var.decoy_scripts.token_type != "aws"
  numeric = true
  special = false
}

resource "random_password" "script_secret" {
  for_each = var.decoy_scripts.token_type == "aws" ? toset(local.scripts_selected) : toset([])

  length  = 40
  special = false
}
