# =========================================================================
# Outputs of storage module
# =========================================================================

# KMS Keys
output "kms_key_mnpi_arn" {
  value       = module.storage.kms_key_mnpi_arn
  description = "KMS key ARN for MNPI data encryption"
}

output "kms_key_public_arn" {
  value       = module.storage.kms_key_public_arn
  description = "KMS key ARN for Public data encryption"
}

# Raw Layer Buckets
output "bucket_raw_mnpi_id" {
  value       = module.storage.bucket_raw_mnpi_id
  description = "Raw MNPI bucket name for CDC/Kafka ingestion"
}

output "bucket_raw_public_id" {
  value       = module.storage.bucket_raw_public_id
  description = "Raw Public bucket name for CDC/Kafka ingestion"
}

# Curated Layer Buckets
output "bucket_curated_mnpi_id" {
  value       = module.storage.bucket_curated_mnpi_id
  description = "Curated MNPI bucket name for transformed data"
}

output "bucket_curated_public_id" {
  value       = module.storage.bucket_curated_public_id
  description = "Curated Public bucket name for transformed data"
}

# Analytics Layer Buckets
output "bucket_analytics_mnpi_id" {
  value       = module.storage.bucket_analytics_mnpi_id
  description = "Analytics MNPI bucket name for query-ready data"
}

output "bucket_analytics_public_id" {
  value       = module.storage.bucket_analytics_public_id
  description = "Analytics Public bucket name for query-ready data"
}

# Glue Databases - Raw Layer
output "glue_database_raw_mnpi" {
  value       = module.storage.glue_database_raw_mnpi_name
  description = "Glue database for Raw MNPI data"
}

output "glue_database_raw_public" {
  value       = module.storage.glue_database_raw_public_name
  description = "Glue database for Raw Public data"
}

# Glue Databases - Curated Layer
output "glue_database_curated_mnpi" {
  value       = module.storage.glue_database_curated_mnpi_name
  description = "Glue database for Curated MNPI data"
}

output "glue_database_curated_public" {
  value       = module.storage.glue_database_curated_public_name
  description = "Glue database for Curated Public data"
}

# Glue Databases - Analytics Layer
output "glue_database_analytics_mnpi" {
  value       = module.storage.glue_database_analytics_mnpi_name
  description = "Glue database for Analytics MNPI data"
}

output "glue_database_analytics_public" {
  value       = module.storage.glue_database_analytics_public_name
  description = "Glue database for Analytics Public data"
}

# CloudTrail & Audit
output "cloudtrail_name" {
  value       = module.storage.cloudtrail_name
  description = "CloudTrail trail name for audit logging"
}

output "audit_bucket_name" {
  value       = module.storage.audit_bucket_name
  description = "S3 bucket storing CloudTrail logs"
}

# =========================================================================
# Outputs of database module
# =========================================================================

# KMS Key (created by the module)
output "database_kms_key_arn" {
  description = "KMS key ARN created by database module"
  value       = module.database.kms_key_arn
}

# RDS Instance
output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.endpoint
}

output "database_address" {
  description = "RDS database hostname"
  value       = module.database.address
}

output "database_name" {
  description = "RDS database name"
  value       = module.database.db_name
}

# Secrets
output "database_master_secret_name" {
  description = "Name of the master credentials secret"
  value       = module.database.master_secret_name
}

# Security
output "database_security_group_id" {
  description = "Security group ID for RDS instance"
  value       = module.database.security_group_id
}

# For DMS integration
output "database_resource_id" {
  description = "RDS resource ID (needed for DMS)"
  value       = module.database.db_resource_id
}

# =========================================================================
# Outputs of msk module
# =========================================================================

output "msk_kms_key_arn" {
  description = "KMS key ARN for MSK cluster"
  value       = module.msk.kms_key_arn
}

output "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = module.msk.cluster_arn
}

output "msk_cluster_name" {
  description = "Name of the MSK cluster"
  value       = module.msk.cluster_name
}

output "msk_bootstrap_brokers_scram" {
  description = "MSK bootstrap brokers for SCRAM authentication (use this for DMS)"
  value       = module.msk.bootstrap_brokers_sasl_scram
}

output "msk_bootstrap_brokers_nlb" {
  description = "Stable NLB endpoint (recommended for applications)"
  value       = module.msk.bootstrap_brokers_nlb
}

# Security
output "msk_security_group_id" {
  description = "Security group ID for MSK cluster"
  value       = module.msk.security_group_id
}

# SCRAM Credentials
output "msk_scram_secret_names" {
  description = "SCRAM secret names in Secrets Manager"
  value       = module.msk.scram_secret_names
}

# Network
output "msk_nlb_dns_name" {
  description = "NLB DNS name"
  value       = module.msk.nlb_dns_name
}

output "msk_route53_dns_name" {
  description = "Route53 DNS name (if configured)"
  value       = module.msk.route53_dns_name
}