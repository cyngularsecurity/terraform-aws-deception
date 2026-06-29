terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.0 required: regional kinds use per-resource `region`.
      version = ">= 6.52, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9, < 4.0"
    }
  }
}
