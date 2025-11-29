# =============================================================================
# Storage Module Outputs
# =============================================================================

# KMS Keys
output "kms_key_mnpi_arn" {
  description = "KMS key ARN for MNPI data encryption"
  value       = module.storage.kms_key_mnpi_arn
}

output "kms_key_public_arn" {
  description = "KMS key ARN for Public data encryption"
  value       = module.storage.kms_key_public_arn
}

# Raw Layer Buckets
output "bucket_raw_mnpi_arn" {
  description = "ARN of Raw MNPI bucket"
  value       = module.storage.bucket_raw_mnpi_arn
}

output "bucket_raw_mnpi_id" {
  description = "Name of Raw MNPI bucket"
  value       = module.storage.bucket_raw_mnpi_id
}

output "bucket_raw_public_arn" {
  description = "ARN of Raw Public bucket"
  value       = module.storage.bucket_raw_public_arn
}

output "bucket_raw_public_id" {
  description = "Name of Raw Public bucket"
  value       = module.storage.bucket_raw_public_id
}

# Curated Layer Buckets
output "bucket_curated_mnpi_id" {
  description = "Name of Curated MNPI bucket"
  value       = module.storage.bucket_curated_mnpi_id
}

output "bucket_curated_public_id" {
  description = "Name of Curated Public bucket"
  value       = module.storage.bucket_curated_public_id
}

# Analytics Layer Buckets
output "bucket_analytics_mnpi_id" {
  description = "Name of Analytics MNPI bucket"
  value       = module.storage.bucket_analytics_mnpi_id
}

output "bucket_analytics_public_id" {
  description = "Name of Analytics Public bucket"
  value       = module.storage.bucket_analytics_public_id
}

# Glue Databases - Raw Layer
output "glue_database_raw_mnpi" {
  description = "Glue database for Raw MNPI data"
  value       = module.storage.glue_database_raw_mnpi_name
}

output "glue_database_raw_public" {
  description = "Glue database for Raw Public data"
  value       = module.storage.glue_database_raw_public_name
}

# Glue Databases - Curated Layer
output "glue_database_curated_mnpi" {
  description = "Glue database for Curated MNPI data"
  value       = module.storage.glue_database_curated_mnpi_name
}

output "glue_database_curated_public" {
  description = "Glue database for Curated Public data"
  value       = module.storage.glue_database_curated_public_name
}

# Glue Databases - Analytics Layer
output "glue_database_analytics_mnpi" {
  description = "Glue database for Analytics MNPI data"
  value       = module.storage.glue_database_analytics_mnpi_name
}

output "glue_database_analytics_public" {
  description = "Glue database for Analytics Public data"
  value       = module.storage.glue_database_analytics_public_name
}

# CloudTrail & Audit
output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = module.storage.cloudtrail_name
}

output "audit_bucket_name" {
  description = "Audit bucket name"
  value       = module.storage.audit_bucket_name
}

# =============================================================================
# Database Module Outputs
# =============================================================================

output "database_kms_key_arn" {
  description = "KMS key ARN created by database module"
  value       = module.database.kms_key_arn
}

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

output "database_master_secret_name" {
  description = "Name of the master credentials secret"
  value       = module.database.master_secret_name
}

output "database_security_group_id" {
  description = "Security group ID for RDS instance"
  value       = module.database.security_group_id
}

output "database_resource_id" {
  description = "RDS resource ID (needed for DMS)"
  value       = module.database.db_resource_id
}

# =============================================================================
# MSK Module Outputs
# =============================================================================

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
  description = "MSK bootstrap brokers for SCRAM authentication"
  value       = module.msk.bootstrap_brokers_sasl_scram
}

output "msk_bootstrap_brokers_nlb" {
  description = "Stable NLB endpoint (recommended for applications)"
  value       = module.msk.bootstrap_brokers_nlb
}

output "msk_security_group_id" {
  description = "Security group ID for MSK cluster"
  value       = module.msk.security_group_id
}

output "msk_scram_secret_names" {
  description = "SCRAM secret names in Secrets Manager"
  value       = module.msk.scram_secret_names
}

output "msk_nlb_dns_name" {
  description = "NLB DNS name"
  value       = module.msk.nlb_dns_name
}

output "msk_route53_dns_name" {
  description = "Route53 DNS name (if configured)"
  value       = module.msk.route53_dns_name
}
