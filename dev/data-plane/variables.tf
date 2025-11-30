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

variable "msk_security_group_id" {
  type        = string
  description = "MSK security group ID (for Prometheus to scrape brokers)"
}

# =============================================================================
# Database (from Infra Stack)
# =============================================================================

variable "database_master_secret_name" {
  type        = string
  description = "Name of Secrets Manager secret containing database credentials"
}

variable "database_security_group_id" {
  type        = string
  description = "Security group ID for RDS instance"
}

# =============================================================================
# S3 Buckets (from Infra Stack)
# =============================================================================

# Raw Layer - MNPI
variable "bucket_raw_mnpi_arn" {
  type        = string
  description = "ARN of S3 bucket for raw MNPI data"
}

variable "bucket_raw_mnpi_id" {
  type        = string
  description = "Name of S3 bucket for raw MNPI data"
}

# Raw Layer - Public
variable "bucket_raw_public_arn" {
  type        = string
  description = "ARN of S3 bucket for raw Public data"
}

variable "bucket_raw_public_id" {
  type        = string
  description = "Name of S3 bucket for raw Public data"
}

# KMS Keys
variable "kms_key_mnpi_arn" {
  type        = string
  description = "KMS key ARN for MNPI bucket encryption"
}

variable "kms_key_public_arn" {
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

# =============================================================================
# S3 Buckets - Curated & Analytics Layers (for Athena)
# =============================================================================

variable "bucket_curated_mnpi_arn" {
  type        = string
  description = "ARN of S3 bucket for curated MNPI data"
}

variable "bucket_curated_public_arn" {
  type        = string
  description = "ARN of S3 bucket for curated Public data"
}

variable "bucket_analytics_mnpi_arn" {
  type        = string
  description = "ARN of S3 bucket for analytics MNPI data"
}

variable "bucket_analytics_public_arn" {
  type        = string
  description = "ARN of S3 bucket for analytics Public data"
}

# =============================================================================
# Glue Databases (for Athena)
# =============================================================================

variable "glue_database_raw_mnpi" {
  type        = string
  description = "Glue database name for Raw MNPI data"
}

variable "glue_database_raw_public" {
  type        = string
  description = "Glue database name for Raw Public data"
}

variable "glue_database_curated_mnpi" {
  type        = string
  description = "Glue database name for Curated MNPI data"
}

variable "glue_database_curated_public" {
  type        = string
  description = "Glue database name for Curated Public data"
}

variable "glue_database_analytics_mnpi" {
  type        = string
  description = "Glue database name for Analytics MNPI data"
}

variable "glue_database_analytics_public" {
  type        = string
  description = "Glue database name for Analytics Public data"
}

# =============================================================================
# ECS / Streaming Services
# =============================================================================

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of ACM certificate for HTTPS"
}

variable "route53_private_zone_id" {
  type        = string
  description = "Route53 private hosted zone ID"
}

# =============================================================================
# Alerting (PagerDuty) - 参考你以前的设置
# =============================================================================

variable "pagerduty_integration_key_warning" {
  type        = string
  description = "PagerDuty integration key for warning alerts"
  default     = ""
}

variable "pagerduty_integration_key_critical" {
  type        = string
  description = "PagerDuty integration key for critical alerts"
  default     = ""
}
