module "kafka" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//kafka-data-plane?ref=main"

  bootstrap_servers    = var.msk_bootstrap_brokers_nlb
  kafka_admin_username = local.kafka_admin_creds.username
  kafka_admin_password = local.kafka_admin_creds.password
  skip_tls_verify      = var.env == "dev" ? true : false

  msk_cluster_arn  = var.msk_cluster_arn
  msk_cluster_name = var.msk_cluster_name
  common_tags      = var.common_tags

  topics = concat(
    # MNPI Topics
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
          topic_name == "cdc.trades.mnpi" ? {
            "max.message.bytes" = "1048576"
            "segment.ms"        = "3600000"
            "segment.bytes"     = "1073741824"
          } : {}
        )
      }
    ],
    # Public Topics
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
    # Schema History Topic
    [
      {
        name               = local.schema_history_topic
        replication_factor = 3
        partitions         = 1
        config = {
          "retention.ms"        = "-1"
          "cleanup.policy"      = "delete"
          "min.insync.replicas" = "2"
          "compression.type"    = "lz4"
        }
      }
    ]
  )

  # ACL Configuration
  user_acls = {
    # Admin
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

    # Debezium CDC Source Connector
    debezium = [
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
      {
        resource_name = "kafka-cluster"
        resource_type = "Cluster"
        operation     = "IdempotentWrite"
      },
      {
        resource_name = "connect-debezium-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]

    # S3 Sink MNPI Connector
    s3_sink_mnpi = concat(
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
      [
        {
          resource_name = "connect-s3-sink-raw-mnpi-*"
          resource_type = "Group"
          operation     = "Read"
        }
      ]
    )

    # S3 Sink Public Connector
    s3_sink_public = concat(
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
