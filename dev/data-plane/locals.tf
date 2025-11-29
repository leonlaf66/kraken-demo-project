data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get Admin Password from Secrets Manager

data "aws_secretsmanager_secret" "kafka_admin" {
  name = var.msk_scram_secret_names["admin"]
}

data "aws_secretsmanager_secret_version" "kafka_admin" {
  secret_id = data.aws_secretsmanager_secret.kafka_admin.id
}

# =========================================================================
# Secrets Manager - SCRAM Credentials
# =========================================================================

data "aws_secretsmanager_secret" "debezium" {
  name = var.msk_scram_secret_names["debezium"]
}

data "aws_secretsmanager_secret_version" "debezium" {
  secret_id = data.aws_secretsmanager_secret.debezium.id
}

data "aws_secretsmanager_secret" "s3_sink_mnpi" {
  name = var.msk_scram_secret_names["s3_sink_mnpi"]
}

data "aws_secretsmanager_secret_version" "s3_sink_mnpi" {
  secret_id = data.aws_secretsmanager_secret.s3_sink_mnpi.id
}

data "aws_secretsmanager_secret" "s3_sink_public" {
  name = var.msk_scram_secret_names["s3_sink_public"]
}

data "aws_secretsmanager_secret_version" "s3_sink_public" {
  secret_id = data.aws_secretsmanager_secret.s3_sink_public.id
}

# =========================================================================
# Secrets Manager - Database Credentials
# =========================================================================

data "aws_secretsmanager_secret" "database" {
  name = var.database_secret_name
}

data "aws_secretsmanager_secret_version" "database" {
  secret_id = data.aws_secretsmanager_secret.database.id
}

locals {
#kafka
  kafka_admin_creds = jsondecode(data.aws_secretsmanager_secret_version.kafka_admin.secret_string)

#msk connect
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  # MSK Bootstrap endpoint via Route53 (NLB backed)
  msk_bootstrap_endpoint = var.msk_bootstrap_endpoint_route53

  # Topic naming
  cdc_topics_mnpi = [
    "cdc.trades.mnpi",
    "cdc.orders.mnpi",
    "cdc.positions.mnpi"
  ]

  cdc_topics_public = [
    "cdc.market_data.public",
    "cdc.reference_data.public"
  ]

  all_cdc_topics = concat(local.cdc_topics_mnpi, local.cdc_topics_public)

  # Parse credentials from Secrets Manager
  debezium_creds       = jsondecode(data.aws_secretsmanager_secret_version.debezium.secret_string)
  s3_sink_mnpi_creds   = jsondecode(data.aws_secretsmanager_secret_version.s3_sink_mnpi.secret_string)
  s3_sink_public_creds = jsondecode(data.aws_secretsmanager_secret_version.s3_sink_public.secret_string)
  database_creds       = jsondecode(data.aws_secretsmanager_secret_version.database.secret_string)

  # SCRAM JAAS config for each connector
  debezium_scram_jaas_config       = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.debezium_creds.username}\" password=\"${local.debezium_creds.password}\";"
  s3_sink_mnpi_scram_jaas_config   = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.s3_sink_mnpi_creds.username}\" password=\"${local.s3_sink_mnpi_creds.password}\";"
  s3_sink_public_scram_jaas_config = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.s3_sink_public_creds.username}\" password=\"${local.s3_sink_public_creds.password}\";"
}