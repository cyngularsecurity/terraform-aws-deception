terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "deception" {
  source = "cyngularsecurity/deception/aws"
  # version = "x.y.z"  # pin once published to the registry

  regions = ["us-east-1"]

  tracking_tag_key   = "cost-center"
  tracking_tag_value = "CC-9042"

  iam_user  = { enabled = true, count = 2, name_prefix = "svc-admin" }
  iam_role  = { enabled = true, count = 1, name_prefix = "poweruser" }
  s3_bucket = { enabled = true, count = 1, name_prefix = "legacy-backups" }
  secret    = { enabled = true, count = 1, name_prefix = "prod-db-credentials" }
}

output "decoy_iam_user_arns" {
  value = module.deception.iam_user_arns
}
