terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.0 required: regional kinds use per-resource `region`.
      version = ">= 6.52"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9"
    }
  }
}
