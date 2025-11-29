# =============================================================================
# Core Variables
# =============================================================================

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "kraken-demo"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

# =============================================================================
# Network Variables
# =============================================================================

variable "private_hosted_zone_id" {
  type        = string
  description = "Private hosted zone ID for Route53 record (leave empty to skip)"
  default     = ""
}
