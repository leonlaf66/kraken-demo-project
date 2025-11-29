# 1. Debezium CDC Source Connector
module "debezium_cdc_source" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module/msk-connect?ref=main"

  connector_name       = "debezium-postgres-cdc-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "source"
  kafkaconnect_version = "2.7.1"

  # Network
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # MSK - Route53 endpoint with SCRAM
  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  # Kafka Permissions
  kafka_topics_write = local.all_cdc_topics
  kafka_topics_read  = []

  # RDS Secret (for IAM permissions to read secret)
  rds_secret_arn      = data.aws_secretsmanager_secret.database.arn
  secrets_kms_key_arn = var.secrets_kms_key_arn

  # Plugin
  custom_plugin_arn        = var.debezium_plugin_arn
  custom_plugin_revision   = var.debezium_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  # No S3 for source connector
  s3_sink_bucket_arn = null
  s3_kms_key_arn     = null

  # Connector Configuration
  connector_configuration = {
    # Connector Class
    "connector.class" = "io.debezium.connector.postgresql.PostgresConnector"

    # Database Connection (from Secrets Manager)
    "database.hostname"    = local.database_creds.host
    "database.port"        = tostring(local.database_creds.port)
    "database.user"        = local.database_creds.username
    "database.password"    = local.database_creds.password
    "database.dbname"      = local.database_creds.dbname
    "database.server.name" = "kraken-cdc"

    # PostgreSQL Logical Replication
    "plugin.name"                 = "pgoutput"
    "slot.name"                   = "debezium_cdc_slot"
    "publication.name"            = "debezium_publication"
    "publication.autocreate.mode" = "filtered"

    # Table Filtering
    "table.include.list" = "public.trades,public.orders,public.positions,public.market_data,public.reference_data"

    # Topic Routing Transforms
    "topic.prefix" = "cdc"
    "transforms"   = "routeMNPI,routePublic"

    "transforms.routeMNPI.type"        = "org.apache.kafka.connect.transforms.RegexRouter"
    "transforms.routeMNPI.regex"       = "cdc\\.public\\.(trades|orders|positions)"
    "transforms.routeMNPI.replacement" = "cdc.$1.mnpi"

    "transforms.routePublic.type"        = "org.apache.kafka.connect.transforms.RegexRouter"
    "transforms.routePublic.regex"       = "cdc\\.public\\.(market_data|reference_data)"
    "transforms.routePublic.replacement" = "cdc.$1.public"

    # Snapshot
    "snapshot.mode" = "initial"

    # Schema History - With SCRAM Auth
    "schema.history.internal.kafka.bootstrap.servers" = local.msk_bootstrap_endpoint
    "schema.history.internal.kafka.topic"             = "schema-changes.kraken-cdc"

    "schema.history.internal.producer.security.protocol" = "SASL_SSL"
    "schema.history.internal.producer.sasl.mechanism"    = "SCRAM-SHA-512"
    "schema.history.internal.producer.sasl.jaas.config"  = local.debezium_scram_jaas_config

    "schema.history.internal.consumer.security.protocol" = "SASL_SSL"
    "schema.history.internal.consumer.sasl.mechanism"    = "SCRAM-SHA-512"
    "schema.history.internal.consumer.sasl.jaas.config"  = local.debezium_scram_jaas_config

    # Converters
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable" = "false"

    # Performance
    "max.batch.size"   = "2048"
    "max.queue.size"   = "8192"
    "poll.interval.ms" = "100"
    "tasks.max"        = "1"
  }

  # Autoscaling
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 2
  autoscaling_scale_in_cpu     = 20
  autoscaling_scale_out_cpu    = 80

  log_retention_in_days = 7
  common_tags           = var.common_tags
}

# =========================================================================
# 2. S3 Sink Connector - MNPI Zone
# =========================================================================

module "s3_sink_mnpi" {
  source = "../../../tfm/modules/msk-connect"

  connector_name       = "s3-sink-raw-mnpi-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "sink"
  kafkaconnect_version = "2.7.1"

  # Network
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # MSK - Route53 endpoint with SCRAM
  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  # Kafka Permissions - MNPI topics only
  kafka_topics_write = []
  kafka_topics_read  = local.cdc_topics_mnpi

  # No RDS access needed
  rds_secret_arn      = null
  secrets_kms_key_arn = null

  # Plugin
  custom_plugin_arn        = var.s3_sink_plugin_arn
  custom_plugin_revision   = var.s3_sink_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  # S3 - MNPI bucket only
  s3_sink_bucket_arn = var.s3_bucket_raw_mnpi_arn
  s3_kms_key_arn     = var.s3_kms_key_mnpi_arn

  # Connector Configuration
  connector_configuration = {
    "connector.class" = "io.confluent.connect.s3.S3SinkConnector"

    # Topics - MNPI only
    "topics" = join(",", local.cdc_topics_mnpi)

    # S3
    "s3.bucket.name" = var.s3_bucket_raw_mnpi_name
    "s3.region"      = local.region

    # Storage
    "storage.class" = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"  = "io.confluent.connect.s3.format.json.JsonFormat"

    # Partitioning - Hourly for MNPI (high volume)
    "partitioner.class"     = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
    "path.format"           = "'year'=YYYY/'month'=MM/'day'=dd/'hour'=HH"
    "partition.duration.ms" = "3600000"
    "locale"                = "en-US"
    "timezone"              = "UTC"
    "timestamp.extractor"   = "Record"

    # Flush
    "flush.size"                  = "1000"
    "rotate.interval.ms"          = "60000"
    "rotate.schedule.interval.ms" = "3600000"

    # Converters
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable" = "false"

    # Error Handling
    "errors.tolerance"            = "all"
    "errors.log.enable"           = "true"
    "errors.log.include.messages" = "true"

    "tasks.max" = "3"
  }

  # Autoscaling - Higher for MNPI
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 4
  autoscaling_scale_in_cpu     = 20
  autoscaling_scale_out_cpu    = 80

  log_retention_in_days = 7
  common_tags           = var.common_tags
}

# =========================================================================
# 3. S3 Sink Connector - Public Zone
# =========================================================================

module "s3_sink_public" {
  source = "../../../tfm/modules/msk-connect"

  connector_name       = "s3-sink-raw-public-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "sink"
  kafkaconnect_version = "2.7.1"

  # Network
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # MSK - Route53 endpoint with SCRAM
  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  # Kafka Permissions - Public topics only
  kafka_topics_write = []
  kafka_topics_read  = local.cdc_topics_public

  # No RDS access needed
  rds_secret_arn      = null
  secrets_kms_key_arn = null

  # Plugin
  custom_plugin_arn        = var.s3_sink_plugin_arn
  custom_plugin_revision   = var.s3_sink_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  # S3 - Public bucket only
  s3_sink_bucket_arn = var.s3_bucket_raw_public_arn
  s3_kms_key_arn     = var.s3_kms_key_public_arn

  # Connector Configuration
  connector_configuration = {
    "connector.class" = "io.confluent.connect.s3.S3SinkConnector"

    # Topics - Public only
    "topics" = join(",", local.cdc_topics_public)

    # S3
    "s3.bucket.name" = var.s3_bucket_raw_public_name
    "s3.region"      = local.region

    # Storage
    "storage.class" = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"  = "io.confluent.connect.s3.format.json.JsonFormat"

    # Partitioning - Daily for Public (lower volume)
    "partitioner.class"     = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
    "path.format"           = "'year'=YYYY/'month'=MM/'day'=dd"
    "partition.duration.ms" = "86400000"
    "locale"                = "en-US"
    "timezone"              = "UTC"
    "timestamp.extractor"   = "Record"

    # Flush
    "flush.size"                  = "5000"
    "rotate.interval.ms"          = "300000"
    "rotate.schedule.interval.ms" = "86400000"

    # Converters
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable" = "false"

    # Error Handling
    "errors.tolerance"            = "all"
    "errors.log.enable"           = "true"
    "errors.log.include.messages" = "true"

    "tasks.max" = "2"
  }

  # Autoscaling
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 3
  autoscaling_scale_in_cpu     = 20
  autoscaling_scale_out_cpu    = 80

  log_retention_in_days = 7
  common_tags           = var.common_tags
}
