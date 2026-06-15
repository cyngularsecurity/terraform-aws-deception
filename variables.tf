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

# --- Tracking tag (attribution supplement, item 10) -------------------------
# Key ideally mimics a tag the client already uses; value is something the
# detection owner recognizes. Both are caller-supplied — no hardcoded
# convention, no Cyngular string baked in.
variable "tracking_tag_key" {
  description = "Tag key applied to every decoy resource for attribution. Should look like a normal client tag."
  type        = string
}

variable "tracking_tag_value" {
  description = "Tag value applied to every decoy resource for attribution."
  type        = string
}

# --- Per-kind enable + count + names ----------------------------------------
# Each kind: enable flag, count, and a name prefix the instances derive from.
# Names must be intriguing-but-generic (admin/poweruser-style); no
# deception/decoy/cyngular token anywhere.

variable "iam_user" {
  description = "IAM user honeytokens. Inert (flat Deny *), access keys generated as bait."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}
}

variable "iam_role" {
  description = "IAM role honeytokens. Empty trust policy (not assumable) + flat Deny *."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}
}

variable "s3_bucket" {
  description = "S3 bucket decoys. Block Public Access on, no restrictive bucket policy, decoy objects inside. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}
}

variable "secret" {
  description = "Secrets Manager decoys. Real-looking fake value, no restrictive resource policy. Fans out over var.regions."
  type = object({
    enabled     = optional(bool, false)
    count       = optional(number, 0)
    name_prefix = optional(string, "")
  })
  default = {}
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
