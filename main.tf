# =============================================================================
# terraform-aws-deception
# Client-run module that plants inert AWS decoy resources.
#
# Design (Track D.1, locked 2026-06-04):
#   - Resources are freely IAM-reachable but internet-unreachable; the touch
#     is the signal.
#   - Identities are inert by policy (flat Deny *); IAM role additionally has
#     an empty trust policy (not assumable).
#   - Nothing in-account references Cyngular (names, tags, descriptions,
#     paths, provider default-tags).
#   - Attribution = created ARNs/names (outputs) + a caller-supplied tracking
#     tag. No observer principal, no steganographic marker.
# =============================================================================
