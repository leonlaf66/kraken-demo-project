# =============================================================================
# Kafka Topics and ACLs Module
# =============================================================================
# Assignment Requirements:
# - CDC topics for MNPI data (trades, orders, positions)
# - CDC topics for Public data (market_data, reference_data)
# - Schema history topic for Debezium
# - Least privilege ACLs for MSK Connect connectors
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
  # Topics
  # ===========================================================================
  topics = [
    # -----------------------------------------
    # CDC Topics - MNPI Data (Sensitive)
    # -----------------------------------------
    {
      name               = "cdc.trades.mnpi"
      replication_factor = 3
      partitions         = 6
      config = {
        "retention.ms"        = "604800000"   # 7 days
        "compression.type"    = "lz4"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "delete"
        "max.message.bytes"   = "1048576"
        "segment.ms"          = "3600000"
        "segment.bytes"       = "1073741824"
      }
    },
    {
      name               = "cdc.orders.mnpi"
      replication_factor = 3
      partitions         = 6
      config = {
        "retention.ms"        = "604800000"
        "compression.type"    = "lz4"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "delete"
      }
    },
    {
      name               = "cdc.positions.mnpi"
      replication_factor = 3
      partitions         = 3
      config = {
        "retention.ms"        = "604800000"
        "compression.type"    = "lz4"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "delete"
      }
    },

    # -----------------------------------------
    # CDC Topics - Public Data (Non-Sensitive)
    # -----------------------------------------
    {
      name               = "cdc.market_data.public"
      replication_factor = 3
      partitions         = 9
      config = {
        "retention.ms"        = "604800000"
        "compression.type"    = "snappy"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "delete"
      }
    },
    {
      name               = "cdc.reference_data.public"
      replication_factor = 3
      partitions         = 3
      config = {
        "retention.ms"        = "2592000000"  # 30 days
        "compression.type"    = "snappy"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "compact"
      }
    },

    # -----------------------------------------
    # Debezium Internal Topic
    # -----------------------------------------
    {
      name               = "schema-changes.kraken-cdc"
      replication_factor = 3
      partitions         = 1
      config = {
        "retention.ms"        = "-1"          # Infinite retention
        "cleanup.policy"      = "delete"
        "min.insync.replicas" = "2"
        "compression.type"    = "lz4"
      }
    }
  ]

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
    # -----------------------------------------
    s3_sink_mnpi = [
      {
        resource_name = "cdc.trades.mnpi"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.trades.mnpi"
        resource_type = "Topic"
        operation     = "Describe"
      },
      {
        resource_name = "cdc.orders.mnpi"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.orders.mnpi"
        resource_type = "Topic"
        operation     = "Describe"
      },
      {
        resource_name = "cdc.positions.mnpi"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.positions.mnpi"
        resource_type = "Topic"
        operation     = "Describe"
      },
      # Consumer group
      {
        resource_name = "connect-s3-sink-raw-mnpi-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]

    # -----------------------------------------
    # S3 Sink Public Connector
    # -----------------------------------------
    s3_sink_public = [
      {
        resource_name = "cdc.market_data.public"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.market_data.public"
        resource_type = "Topic"
        operation     = "Describe"
      },
      {
        resource_name = "cdc.reference_data.public"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.reference_data.public"
        resource_type = "Topic"
        operation     = "Describe"
      },
      # Consumer group
      {
        resource_name = "connect-s3-sink-raw-public-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]
  }
}
