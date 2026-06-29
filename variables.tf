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
  validation {
    condition     = length(var.regions) == length(distinct(var.regions))
    error_message = "regions must not contain duplicates."
  }
  validation {
    condition     = length(var.regions) <= 25
    error_message = "regions must contain at most 25 entries."
  }
  validation {
    condition     = alltrue([for region in var.regions : can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", region))])
    error_message = "regions must contain valid AWS region names such as us-east-1."
  }
}

# --- Tracking tag (attribution supplement) ---------------------------------
variable "tracking_tag_key" {
  description = "Tag key applied to every decoy resource for attribution. Should look like a normal client tag."
  type        = string

  validation {
    condition     = length(var.tracking_tag_key) > 0 && length(var.tracking_tag_key) <= 128 && !startswith(lower(var.tracking_tag_key), "aws:")
    error_message = "tracking_tag_key must be 1-128 characters and must not start with the reserved aws: prefix."
  }
}

variable "tracking_tag_value" {
  description = "Tag value applied to every decoy resource for attribution."
  type        = string

  validation {
    condition     = length(var.tracking_tag_value) <= 256
    error_message = "tracking_tag_value must be at most 256 characters."
  }
}

variable "guardrail_admin_principal_arns" {
  description = "Additional client IAM principal ARN patterns exempt from deny-only resource guardrails for maintenance. The current Terraform caller is exempt automatically."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.guardrail_admin_principal_arns : length(arn) > 0 && length(arn) <= 2048 && can(regex("^arn:(aws|aws-us-gov|aws-cn):", arn))])
    error_message = "guardrail_admin_principal_arns entries must be non-empty AWS ARN patterns."
  }
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
    condition     = !var.iam_user.enabled || (var.iam_user.count >= 1 && var.iam_user.count <= 100 && floor(var.iam_user.count) == var.iam_user.count)
    error_message = "iam_user.count must be an integer from 1 to 100 when iam_user.enabled is true."
  }
  validation {
    condition     = !var.iam_user.enabled || can(regex("^[A-Za-z0-9+=,.@_-]{1,55}$", var.iam_user.name_prefix))
    error_message = "iam_user.name_prefix must be 1-55 IAM-safe characters: letters, digits, +=,.@_-, when iam_user.enabled is true."
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
    condition     = !var.iam_role.enabled || (var.iam_role.count >= 1 && var.iam_role.count <= 100 && floor(var.iam_role.count) == var.iam_role.count)
    error_message = "iam_role.count must be an integer from 1 to 100 when iam_role.enabled is true."
  }
  validation {
    condition     = !var.iam_role.enabled || can(regex("^[A-Za-z0-9+=,.@_-]{1,55}$", var.iam_role.name_prefix))
    error_message = "iam_role.name_prefix must be 1-55 IAM-safe characters: letters, digits, +=,.@_-, when iam_role.enabled is true."
  }
}

variable "s3_bucket" {
  description = "S3 bucket decoys. Block Public Access on, read-reachable, mutation-guarded, decoy objects inside. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.s3_bucket.enabled || (var.s3_bucket.count >= 1 && floor(var.s3_bucket.count) == var.s3_bucket.count && length(var.regions) * var.s3_bucket.count <= 100)
    error_message = "s3_bucket.count must be an integer >= 1 and regions * s3_bucket.count must be <= 100 when s3_bucket.enabled is true."
  }
  # Prefix gets a "-<8 hex>" suffix; constrain it so the 3-63 char DNS-safe
  # S3 bucket naming rules always hold.
  validation {
    condition     = !var.s3_bucket.enabled || (can(regex("^[a-z0-9]([a-z0-9.-]{0,52}[a-z0-9])?$", var.s3_bucket.name_prefix)) && !can(regex("\\.\\.|\\.\\-|\\-\\.", var.s3_bucket.name_prefix)))
    error_message = "s3_bucket.name_prefix must be 1-54 DNS-safe chars, start/end with a lowercase letter or digit, and not contain consecutive dots or dot-hyphen adjacency."
  }
}

variable "secret" {
  description = "Secrets Manager decoys. Read-reachable, mutation-guarded, real-looking fake value. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}

  validation {
    condition     = !var.secret.enabled || (var.secret.count >= 1 && floor(var.secret.count) == var.secret.count && length(var.regions) * var.secret.count <= 100)
    error_message = "secret.count must be an integer >= 1 and regions * secret.count must be <= 100 when secret.enabled is true."
  }
  validation {
    condition     = !var.secret.enabled || can(regex("^[A-Za-z0-9/_+=.@-]{1,503}$", var.secret.name_prefix))
    error_message = "secret.name_prefix must be 1-503 Secrets Manager-safe characters: letters, digits, /_+=.@-, when secret.enabled is true."
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

  validation {
    condition     = length(var.lure_tags) <= 49
    error_message = "lure_tags must contain at most 49 tags so the tracking tag can fit within the AWS 50-tag limit."
  }
  validation {
    condition     = alltrue([for key, value in var.lure_tags : length(key) > 0 && length(key) <= 128 && !startswith(lower(key), "aws:") && length(value) <= 256])
    error_message = "lure_tags keys must be 1-128 chars, must not start with aws:, and values must be at most 256 chars."
  }
}
