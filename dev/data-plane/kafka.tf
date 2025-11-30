# =============================================================================
# Kafka Topics and ACLs Module
# =============================================================================
# Assignment Requirements:
# - CDC topics for MNPI data (trades, orders, positions)
# - CDC topics for Public data (market_data, reference_data)
# - Schema history topic for Debezium
# - Least privilege ACLs for MSK Connect connectors
#
# FIX: Topics now derived from local.cdc_topic_config_* (single source of truth)
# =============================================================================

module "kafka" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//kafka-data-plane?ref=main"

  bootstrap_servers    = var.msk_bootstrap_brokers_nlb
  kafka_admin_username = local.kafka_admin_creds.username
  kafka_admin_password = local.kafka_admin_creds.password
  skip_tls_verify      = var.env == "dev" ? true : false

  msk_cluster_arn  = var.msk_cluster_arn
  msk_cluster_name = var.msk_cluster_name
  common_tags      = var.common_tags

  # ===========================================================================
  # Topics - FIX: Now derived from local.cdc_topic_config_* 
  # ===========================================================================
  topics = concat(
    # MNPI Topics (from local config)
    [
      for topic_name, config in local.cdc_topic_config_mnpi : {
        name               = topic_name
        replication_factor = config.replication_factor
        partitions         = config.partitions
        config = merge(
          {
            "retention.ms"        = config.retention_ms
            "compression.type"    = config.compression
            "min.insync.replicas" = "2"
            "cleanup.policy"      = lookup(config, "cleanup_policy", "delete")
          },
          # Additional config for high-volume topics
          topic_name == "cdc.trades.mnpi" ? {
            "max.message.bytes" = "1048576"
            "segment.ms"        = "3600000"
            "segment.bytes"     = "1073741824"
          } : {}
        )
      }
    ],
    # Public Topics (from local config)
    [
      for topic_name, config in local.cdc_topic_config_public : {
        name               = topic_name
        replication_factor = config.replication_factor
        partitions         = config.partitions
        config = {
          "retention.ms"        = config.retention_ms
          "compression.type"    = config.compression
          "min.insync.replicas" = "2"
          "cleanup.policy"      = lookup(config, "cleanup_policy", "delete")
        }
      }
    ],
    # Schema History Topic (from local)
    [
      {
        name               = local.schema_history_topic
        replication_factor = 3
        partitions         = 1
        config = {
          "retention.ms"        = "-1" # Infinite retention
          "cleanup.policy"      = "delete"
          "min.insync.replicas" = "2"
          "compression.type"    = "lz4"
        }
      }
    ]
  )

  # ===========================================================================
  # ACL Configuration - Least Privilege
  # ===========================================================================
  # Users:
  #   admin          - Cluster management
  #   debezium       - CDC Source Connector
  #   s3_sink_mnpi   - S3 Sink for MNPI data
  #   s3_sink_public - S3 Sink for Public data
  # ===========================================================================

  user_acls = {
    # -----------------------------------------
    # Admin - Full Access
    # -----------------------------------------
    admin = [
      {
        resource_name = "kafka-cluster"
        resource_type = "Cluster"
        operation     = "All"
      },
      {
        resource_name = "*"
        resource_type = "Topic"
        operation     = "All"
      },
      {
        resource_name = "*"
        resource_type = "Group"
        operation     = "All"
      }
    ]

    # -----------------------------------------
    # Debezium CDC Source Connector
    # -----------------------------------------
    debezium = [
      # Write to CDC topics
      {
        resource_name = "cdc.*"
        resource_type = "Topic"
        operation     = "Write"
      },
      {
        resource_name = "cdc.*"
        resource_type = "Topic"
        operation     = "Describe"
      },
      {
        resource_name = "cdc.*"
        resource_type = "Topic"
        operation     = "Create"
      },
      # Schema history topic
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Write"
      },
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Describe"
      },
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Create"
      },
      # Cluster permission
      {
        resource_name = "kafka-cluster"
        resource_type = "Cluster"
        operation     = "IdempotentWrite"
      },
      # Consumer group
      {
        resource_name = "connect-debezium-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]

    # -----------------------------------------
    # S3 Sink MNPI Connector
    # FIX: Now uses local.cdc_topics_mnpi for topic list
    # -----------------------------------------
    s3_sink_mnpi = concat(
      # Read and Describe for each MNPI topic
      flatten([
        for topic in local.cdc_topics_mnpi : [
          {
            resource_name = topic
            resource_type = "Topic"
            operation     = "Read"
          },
          {
            resource_name = topic
            resource_type = "Topic"
            operation     = "Describe"
          }
        ]
      ]),
      # Consumer group
      [
        {
          resource_name = "connect-s3-sink-raw-mnpi-*"
          resource_type = "Group"
          operation     = "Read"
        }
      ]
    )

    # -----------------------------------------
    # S3 Sink Public Connector
    # FIX: Now uses local.cdc_topics_public for topic list
    # -----------------------------------------
    s3_sink_public = concat(
      # Read and Describe for each public topic
      flatten([
        for topic in local.cdc_topics_public : [
          {
            resource_name = topic
            resource_type = "Topic"
            operation     = "Read"
          },
          {
            resource_name = topic
            resource_type = "Topic"
            operation     = "Describe"
          }
        ]
      ]),
      # Consumer group
      [
        {
          resource_name = "connect-s3-sink-raw-public-*"
          resource_type = "Group"
          operation     = "Read"
        }
      ]
    )
  }
}
