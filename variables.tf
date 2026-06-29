# =============================================================================
# Input-variable contract (Track D.1, item 3)
# The UI form / quick-link generator populates these. Every name is
# client-chosen; nothing here defaults to a Cyngular-identifying string.
# =============================================================================

variable "regions" {
  description = "Regions to deploy regional decoy kinds (S3, Secrets Manager) into. IAM is global and ignores this. Default is a single region."
  type        = list(string)
  default     = ["us-east-1"]

  validation {
    condition     = length(var.regions) > 0
    error_message = "At least one region is required."
  }
}

# --- Tracking tag (attribution supplement) ---------------------------------
variable "tracking_tag_key" {
  description = "Tag key applied to every decoy resource for attribution. Should look like a normal client tag."
  type        = string
}

variable "tracking_tag_value" {
  description = "Tag value applied to every decoy resource for attribution."
  type        = string
}

# --- Per-kind enable + count + name prefix ----------------------------------
# name_prefix must be intriguing-but-generic (admin/poweruser-style); no
# deception/decoy/cyngular token anywhere.

variable "iam_user" {
  description = "IAM user honeytokens. Inert (flat Deny *), access keys generated as bait."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.iam_user.enabled || var.iam_user.count >= 1
    error_message = "iam_user.count must be >= 1 when iam_user.enabled is true."
  }
  validation {
    condition     = !var.iam_user.enabled || length(var.iam_user.name_prefix) > 0
    error_message = "iam_user.name_prefix must be non-empty when iam_user.enabled is true."
  }
}

variable "iam_role" {
  description = "IAM role honeytokens. Empty trust policy (not assumable) + flat Deny *."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.iam_role.enabled || var.iam_role.count >= 1
    error_message = "iam_role.count must be >= 1 when iam_role.enabled is true."
  }
  validation {
    condition     = !var.iam_role.enabled || length(var.iam_role.name_prefix) > 0
    error_message = "iam_role.name_prefix must be non-empty when iam_role.enabled is true."
  }
}

variable "s3_bucket" {
  description = "S3 bucket decoys. Block Public Access on, no restrictive bucket policy, decoy objects inside. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.s3_bucket.enabled || var.s3_bucket.count >= 1
    error_message = "s3_bucket.count must be >= 1 when s3_bucket.enabled is true."
  }
  # Prefix gets a "-<8 hex>" suffix; constrain it so the 3-63 char DNS-safe
  # S3 bucket naming rules always hold.
  validation {
    condition     = !var.s3_bucket.enabled || can(regex("^[a-z0-9][a-z0-9.-]{0,53}$", var.s3_bucket.name_prefix))
    error_message = "s3_bucket.name_prefix must be 1-54 chars, start with a lowercase letter or digit, and contain only lowercase letters, digits, hyphens, or dots (S3 bucket naming rules)."
  }
}

variable "secret" {
  description = "Secrets Manager decoys. Real-looking fake value, no restrictive resource policy. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.secret.enabled || var.secret.count >= 1
    error_message = "secret.count must be >= 1 when secret.enabled is true."
  }
  validation {
    condition     = !var.secret.enabled || length(var.secret.name_prefix) > 0
    error_message = "secret.name_prefix must be non-empty when secret.enabled is true."
  }
}

# --- Lure / operational tags ------------------------------------------------
variable "lure_tags" {
  description = "Believable operational tags applied to every decoy so an enumerating principal finds them attractive (e.g. env=prod, owner=legacy-team). No Cyngular reference."
  type        = map(string)
  default = {
    env   = "prod"
    owner = "legacy-team"
  }
}
