#### Storage Module Outputs
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
output "bucket_curated_mnpi_arn" {
  description = "ARN of Curated MNPI bucket"
  value       = module.storage.bucket_curated_mnpi_arn
}

output "bucket_curated_public_arn" {
  description = "ARN of Curated Public bucket"
  value       = module.storage.bucket_curated_public_arn
}

# Analytics Layer Buckets
output "bucket_analytics_mnpi_arn" {
  description = "ARN of Analytics MNPI bucket"
  value       = module.storage.bucket_analytics_mnpi_arn
}

output "bucket_analytics_public_arn" {
  description = "ARN of Analytics Public bucket"
  value       = module.storage.bucket_analytics_public_arn
}

# Glue Databases
output "glue_database_raw_mnpi" {
  description = "Glue database for Raw MNPI data"
  value       = module.storage.glue_database_raw_mnpi_name
}

output "glue_database_raw_public" {
  description = "Glue database for Raw Public data"
  value       = module.storage.glue_database_raw_public_name
}

output "glue_database_curated_mnpi" {
  description = "Glue database for Curated MNPI data"
  value       = module.storage.glue_database_curated_mnpi_name
}

output "glue_database_curated_public" {
  description = "Glue database for Curated Public data"
  value       = module.storage.glue_database_curated_public_name
}

output "glue_database_analytics_mnpi" {
  description = "Glue database for Analytics MNPI data"
  value       = module.storage.glue_database_analytics_mnpi_name
}

output "glue_database_analytics_public" {
  description = "Glue database for Analytics Public data"
  value       = module.storage.glue_database_analytics_public_name
}

#### Database Module Outputs
output "database_master_secret_name" {
  description = "Name of the master credentials secret"
  value       = module.database.master_secret_name
}

output "database_security_group_id" {
  description = "Security group ID for RDS instance"
  value       = module.database.security_group_id
}

#### MSK Module Outputs
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
