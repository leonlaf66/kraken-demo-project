# =============================================================================
# Core Variables
# =============================================================================

variable "env" {
  type        = string
  description = "Environment (dev, qa, prod)"
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "kraken-demo"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

# =============================================================================
# MSK (from Infra Stack)
# =============================================================================

variable "msk_cluster_arn" {
  type        = string
  description = "ARN of the MSK cluster"
}

variable "msk_cluster_name" {
  type        = string
  description = "Name of the MSK cluster"
}

variable "msk_bootstrap_brokers_nlb" {
  type        = string
  description = "MSK bootstrap servers via NLB"
}

variable "msk_kms_key_arn" {
  type        = string
  description = "KMS key ARN for MSK cluster encryption"
}

variable "msk_scram_secret_names" {
  type        = map(string)
  description = "Map of SCRAM user names to their Secrets Manager secret names"
}

# =============================================================================
# Database (from Infra Stack)
# =============================================================================

variable "database_secret_name" {
  type        = string
  description = "Name of Secrets Manager secret containing database credentials"
}

# =============================================================================
# S3 Buckets (from Infra Stack)
# =============================================================================

# Raw Layer - MNPI
variable "s3_bucket_raw_mnpi_arn" {
  type        = string
  description = "ARN of S3 bucket for raw MNPI data"
}

variable "s3_bucket_raw_mnpi_name" {
  type        = string
  description = "Name of S3 bucket for raw MNPI data"
}

variable "s3_kms_key_mnpi_arn" {
  type        = string
  description = "KMS key ARN for MNPI bucket encryption"
}

# Raw Layer - Public
variable "s3_bucket_raw_public_arn" {
  type        = string
  description = "ARN of S3 bucket for raw Public data"
}

variable "s3_bucket_raw_public_name" {
  type        = string
  description = "Name of S3 bucket for raw Public data"
}

variable "s3_kms_key_public_arn" {
  type        = string
  description = "KMS key ARN for Public bucket encryption"
}

# =============================================================================
# Plugin Configuration
# =============================================================================

variable "plugin_bucket_arn" {
  type        = string
  description = "ARN of S3 bucket containing MSK Connect plugins"
}

variable "debezium_plugin_arn" {
  type        = string
  description = "ARN of the Debezium custom plugin"
}

variable "debezium_plugin_revision" {
  type        = number
  default     = 1
  description = "Revision of the Debezium plugin"
}

variable "s3_sink_plugin_arn" {
  type        = string
  description = "ARN of the Confluent S3 Sink custom plugin"
}

variable "s3_sink_plugin_revision" {
  type        = number
  default     = 1
  description = "Revision of the S3 Sink plugin"
}
