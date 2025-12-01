variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "iam_permissions_boundary_arn" {
  type        = string
  description = "ARN of the IAM permissions boundary policy"
  default     = null
}

variable "route53_private_zone_id" {
  type        = string
  description = "Private hosted zone ID for Route53 record (leave empty to skip)"
  default     = ""
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "kraken-demo"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Team    = "SRE"
    Project = "Kraken Demo"
  }
}
