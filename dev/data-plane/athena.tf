module "athena" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//athena?ref=main"

  app_name    = var.app_name
  env         = var.env
  region      = local.region
  account_id  = local.account_id
  common_tags = var.common_tags

  # S3 Buckets
  buckets = {
    raw_mnpi         = var.bucket_raw_mnpi_arn
    raw_public       = var.bucket_raw_public_arn
    curated_mnpi     = var.bucket_curated_mnpi_arn
    curated_public   = var.bucket_curated_public_arn
    analytics_mnpi   = var.bucket_analytics_mnpi_arn
    analytics_public = var.bucket_analytics_public_arn
  }

  # KMS Keys
  kms_keys = {
    mnpi   = var.kms_key_mnpi_arn
    public = var.kms_key_public_arn
  }

  # Glue Databases
  glue_databases = {
    raw_mnpi         = var.glue_database_raw_mnpi
    raw_public       = var.glue_database_raw_public
    curated_mnpi     = var.glue_database_curated_mnpi
    curated_public   = var.glue_database_curated_public
    analytics_mnpi   = var.glue_database_analytics_mnpi
    analytics_public = var.glue_database_analytics_public
  }
}
