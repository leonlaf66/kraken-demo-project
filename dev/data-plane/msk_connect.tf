# Debezium
# Reads from PostgreSQL, writes to Kafka topics
module "debezium_cdc_source" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk-connect?ref=v1.0.0"

  connector_name       = "debezium-postgres-cdc-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "source"
  kafkaconnect_version = "2.7.1"

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  kafka_topics_write = local.all_cdc_topics
  kafka_topics_read  = []

  rds_secret_arn      = data.aws_secretsmanager_secret.database.arn
  secrets_kms_key_arn = null

  custom_plugin_arn        = var.debezium_plugin_arn
  custom_plugin_revision   = var.debezium_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  s3_sink_bucket_arn = null
  s3_kms_key_arn     = null

  # Connector Configuration, document https://debezium.io/documentation/reference/stable/connectors/postgresql.html
  connector_configuration = {
    # Connector Class
    "connector.class" = "io.debezium.connector.postgresql.PostgresConnector"

    # Database Connection - Using Secrets Manager references
    "database.hostname" = "$${secretsManager:${data.aws_secretsmanager_secret.database.arn}:host}"
    "database.port"     = "$${secretsManager:${data.aws_secretsmanager_secret.database.arn}:port}"
    "database.user"     = "$${secretsManager:${data.aws_secretsmanager_secret.database.arn}:username}"
    "database.password" = "$${secretsManager:${data.aws_secretsmanager_secret.database.arn}:password}"
    "database.dbname"   = "$${secretsManager:${data.aws_secretsmanager_secret.database.arn}:dbname}"

    "database.server.name" = "${var.app_name}-cdc"

    # PostgreSQL Logical Replication
    "plugin.name"                 = "pgoutput"
    "slot.name"                   = "debezium_cdc_slot"
    "publication.name"            = "debezium_publication"
    "publication.autocreate.mode" = "filtered"

    # FIX: Table include list derived from topic config
    "table.include.list" = local.debezium_table_include_list

    # Topic Routing
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

    "schema.history.internal.kafka.bootstrap.servers" = local.msk_bootstrap_endpoint
    "schema.history.internal.kafka.topic"             = local.schema_history_topic

    "schema.history.internal.producer.security.protocol" = "SASL_SSL"
    "schema.history.internal.producer.sasl.mechanism"    = "SCRAM-SHA-512"
    "schema.history.internal.producer.sasl.jaas.config"  = local.debezium_scram_jaas_config

    "schema.history.internal.consumer.security.protocol" = "SASL_SSL"
    "schema.history.internal.consumer.sasl.mechanism"    = "SCRAM-SHA-512"
    "schema.history.internal.consumer.sasl.jaas.config"  = local.debezium_scram_jaas_config

    # Converters
    "key.converter"                       = "io.confluent.connect.json.JsonSchemaConverter"
    "key.converter.schema.registry.url"   = local.schema_registry_url
    "value.converter"                     = "io.confluent.connect.json.JsonSchemaConverter"
    "value.converter.schema.registry.url" = local.schema_registry_url

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
  common_tags           = local.common_tags

  depends_on = [module.streaming_services, module.kafka]
}

# S3 Sink Connector - MNPI
# Reads MNPI topics, writes to S3 MNPI bucket
module "s3_sink_mnpi" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk-connect?ref=v1.0.0"

  connector_name       = "s3-sink-raw-mnpi-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "sink"
  kafkaconnect_version = "2.7.1"

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  kafka_topics_write = []
  kafka_topics_read  = local.cdc_topics_mnpi

  rds_secret_arn      = null
  secrets_kms_key_arn = null

  custom_plugin_arn        = var.s3_sink_plugin_arn
  custom_plugin_revision   = var.s3_sink_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  s3_sink_bucket_arn = var.bucket_raw_mnpi_arn
  s3_kms_key_arn     = var.kms_key_mnpi_arn

  # Connector Configuration, document https://docs.confluent.io/kafka-connectors/s3-sink/current/configuration_options.html
  connector_configuration = {
    "connector.class" = "io.confluent.connect.s3.S3SinkConnector"
    "topics"          = join(",", local.cdc_topics_mnpi)

    # S3
    "s3.bucket.name" = var.bucket_raw_mnpi_id
    "s3.region"      = local.region

    # Storage
    "storage.class" = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"  = "io.confluent.connect.s3.format.parquet.ParquetFormat"

    # Partitioning
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

  # Autoscaling
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 4
  autoscaling_scale_in_cpu     = 20
  autoscaling_scale_out_cpu    = 80

  log_retention_in_days = 7
  common_tags           = local.common_tags

  depends_on = [module.streaming_services, module.kafka]
}

# S3 Sink Connector - Public
# Reads Public topics, writes to S3 Public bucket
module "s3_sink_public" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk-connect?ref=v1.0.0"

  connector_name       = "s3-sink-raw-public-${var.env}"
  env                  = var.env
  region               = local.region
  account_id           = local.account_id
  connector_type       = "sink"
  kafkaconnect_version = "2.7.1"

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = local.msk_bootstrap_endpoint
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  kafka_topics_write = []
  kafka_topics_read  = local.cdc_topics_public

  rds_secret_arn      = null
  secrets_kms_key_arn = null

  custom_plugin_arn        = var.s3_sink_plugin_arn
  custom_plugin_revision   = var.s3_sink_plugin_revision
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  s3_sink_bucket_arn = var.bucket_raw_public_arn
  s3_kms_key_arn     = var.kms_key_public_arn

  # Connector Configuration, document https://docs.confluent.io/kafka-connectors/s3-sink/current/configuration_options.html
  connector_configuration = {
    "connector.class" = "io.confluent.connect.s3.S3SinkConnector"
    "topics"          = join(",", local.cdc_topics_public)

    # S3
    "s3.bucket.name" = var.bucket_raw_public_id
    "s3.region"      = local.region

    # Storage
    "storage.class" = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"  = "io.confluent.connect.s3.format.parquet.ParquetFormat"

    # Partitioning
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
  common_tags           = local.common_tags

  depends_on = [module.streaming_services, module.kafka]
}
