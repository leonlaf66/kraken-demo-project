# =============================================================================
# Data Sources
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC and Subnets
data "aws_vpc" "selected" {
  tags = {
    Name = "${var.app_name}-vpc-${var.env}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# Route53 Private Zone - to get zone name for service DNS
data "aws_route53_zone" "private" {
  zone_id      = var.route53_private_zone_id
  private_zone = true
}

# =============================================================================
# Secrets Manager - Kafka Admin Credentials
# =============================================================================

data "aws_secretsmanager_secret" "kafka_admin" {
  name = var.msk_scram_secret_names["admin"]
}

data "aws_secretsmanager_secret_version" "kafka_admin" {
  secret_id = data.aws_secretsmanager_secret.kafka_admin.id
}

# =============================================================================
# Secrets Manager - SCRAM Credentials for Connectors
# =============================================================================

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

# =============================================================================
# Secrets Manager - Database Credentials
# =============================================================================

data "aws_secretsmanager_secret" "database" {
  name = var.database_master_secret_name
}

data "aws_secretsmanager_secret_version" "database" {
  secret_id = data.aws_secretsmanager_secret.database.id
}

# =============================================================================
# MSK Broker Nodes (for Prometheus scraping)
# =============================================================================

data "aws_msk_cluster" "main" {
  cluster_name = var.msk_cluster_name
}

data "aws_msk_broker_nodes" "main" {
  cluster_arn = data.aws_msk_cluster.main.arn
}

# =============================================================================
# Locals
# =============================================================================

locals {
  # Naming
  app_name    = var.app_name
  environment = var.env
  common_tags = var.common_tags

  # AWS Context
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  # Network (from data sources)
  vpc_id             = data.aws_vpc.selected.id
  vpc_cidr           = data.aws_vpc.selected.cidr_block
  private_subnet_ids = data.aws_subnets.private.ids

  # MSK Bootstrap endpoint via NLB
  msk_bootstrap_endpoint = var.msk_bootstrap_brokers_nlb

  # =============================================================================
  # Topic Naming
  # =============================================================================

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

  # =============================================================================
  # Credentials Parsing
  # =============================================================================

  kafka_admin_creds    = jsondecode(data.aws_secretsmanager_secret_version.kafka_admin.secret_string)
  debezium_creds       = jsondecode(data.aws_secretsmanager_secret_version.debezium.secret_string)
  s3_sink_mnpi_creds   = jsondecode(data.aws_secretsmanager_secret_version.s3_sink_mnpi.secret_string)
  s3_sink_public_creds = jsondecode(data.aws_secretsmanager_secret_version.s3_sink_public.secret_string)
  database_creds       = jsondecode(data.aws_secretsmanager_secret_version.database.secret_string)

  # SCRAM JAAS config for each connector
  debezium_scram_jaas_config       = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.debezium_creds.username}\" password=\"${local.debezium_creds.password}\";"
  s3_sink_mnpi_scram_jaas_config   = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.s3_sink_mnpi_creds.username}\" password=\"${local.s3_sink_mnpi_creds.password}\";"
  s3_sink_public_scram_jaas_config = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.s3_sink_public_creds.username}\" password=\"${local.s3_sink_public_creds.password}\";"
  kafka_admin_scram_jaas_config    = "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${local.kafka_admin_creds.username}\" password=\"${local.kafka_admin_creds.password}\";"

  # =============================================================================
  # ECS Container Images
  # =============================================================================

  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"

  schema_registry_image = "${local.ecr_registry}/confluentinc/cp-schema-registry:${data.aws_ssm_parameter.schema_registry_image_tag.value}"
  cruise_control_image  = "${local.ecr_registry}/linkedin/cruise-control:${data.aws_ssm_parameter.cruise_control_image_tag.value}"
  prometheus_image      = "${local.ecr_registry}/prom/prometheus:${data.aws_ssm_parameter.prometheus_image_tag.value}"
  alertmanager_image    = "${local.ecr_registry}/prom/alertmanager:${data.aws_ssm_parameter.alertmanager_image_tag.value}"

  # Schema Registry URL (internal)
  # Schema Registry URL (via ALB Route53 record)
  # Route53 record name = service key, zone name from data source
  route53_zone_name   = trimsuffix(data.aws_route53_zone.private.name, ".")
  schema_registry_url = "http://schema-registry.${local.route53_zone_name}:8081"

  # Kafka credentials secret ARN
  kafka_credentials_secret_arn = data.aws_secretsmanager_secret.kafka_admin.arn

  # =============================================================================
  # Cruise Control Configuration (参考你以前的设置)
  # =============================================================================

  cruise_control_goals = "com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal,com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal"

  cruise_control_properties = {
    "bootstrap.servers"                     = local.msk_bootstrap_endpoint
    "kafka.broker.failure.detection.enable" = "true"
    "security.protocol"                     = "SASL_SSL"
    "sasl.mechanism"                        = "SCRAM-SHA-512"
    "sasl.jaas.config"                      = local.kafka_admin_scram_jaas_config
    "ssl.endpoint.identification.algorithm" = ""
    "sample.store.topic.auto.create"        = "true"
    "sample.store.topic.replication.factor" = "2"
    # Self-healing
    "self.healing.enabled"                = "false"
    "self.healing.broker.failure.enabled" = "false"
    "self.healing.goal.violation.enabled" = "false"
    # Goals
    "default.goals" = local.cruise_control_goals
  }

  # =============================================================================
  # Prometheus Configuration (参考你以前的设置)
  # =============================================================================

  # MSK broker hostnames for scraping
  msk_broker_hostnames     = [for node in data.aws_msk_broker_nodes.main.node_info_list : one(node.endpoints)]
  msk_jmx_targets          = [for host in local.msk_broker_hostnames : "${host}:11001"]
  msk_node_exporter_targets = [for host in local.msk_broker_hostnames : "${host}:11002"]

  # Route53 private zone name (from variable)
  # DNS records created by ecs-service module: {service-name}.{zone_name}
  # e.g., alertmanager.kraken-demo-dev.internal, cruise-control.kraken-demo-dev.internal

  prometheus_config_content = <<-EOT
    global:
      scrape_interval: 30s
    rule_files:
      - "/etc/prometheus/msk_alerts.yml"
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
          - 'alertmanager.${local.route53_zone_name}:9093'
    scrape_configs:
      - job_name: 'msk-jmx-exporter'
        static_configs:
          - targets: ${jsonencode(local.msk_jmx_targets)}
      - job_name: 'msk-node-exporter'
        static_configs:
          - targets: ${jsonencode(local.msk_node_exporter_targets)}
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'cruise-control'
        static_configs:
          - targets: ['cruise-control.${local.route53_zone_name}:9090']
  EOT

  # =============================================================================
  # Prometheus Alert Rules (参考你以前的设置)
  # =============================================================================

  broker_alert_rules = [
    {
      alert = "MSKBrokerDiskUsageHigh"
      expr  = "100 - (node_filesystem_avail_bytes{job=\"msk-node-exporter\", mountpoint=\"/kafka/datalogs\"} / node_filesystem_size_bytes{job=\"msk-node-exporter\", mountpoint=\"/kafka/datalogs\"} * 100) > 70"
      for   = "5m"
      labels = {
        severity = "warning"
      }
      annotations = {
        summary     = "[${var.msk_cluster_name}] MSK Broker Disk Usage High (instance {{ $labels.instance }})"
        description = "Disk usage on broker {{ $labels.instance }} has been over 70% for 5 minutes."
      }
    },
    {
      alert = "MSKBrokerDiskUsageCritical"
      expr  = "100 - (node_filesystem_avail_bytes{job=\"msk-node-exporter\", mountpoint=\"/kafka/datalogs\"} / node_filesystem_size_bytes{job=\"msk-node-exporter\", mountpoint=\"/kafka/datalogs\"} * 100) > 80"
      for   = "5m"
      labels = {
        severity = "critical"
      }
      annotations = {
        summary     = "[${var.msk_cluster_name}] MSK Broker Disk Usage Critical (instance {{ $labels.instance }})"
        description = "Disk usage on broker {{ $labels.instance }} has been over 80% for 5 minutes."
      }
    },
    {
      alert = "MSKBrokerCPUHigh"
      expr  = "(1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"msk-node-exporter\", mode=\"idle\"}[5m]))) * 100 > 50"
      for   = "5m"
      labels = {
        severity = "warning"
      }
      annotations = {
        summary     = "[${var.msk_cluster_name}] MSK Broker CPU High (instance {{ $labels.instance }})"
        description = "CPU utilization on broker {{ $labels.instance }} has been over 50% for 5 minutes."
      }
    },
    {
      alert = "MSKBrokerUnderReplicatedPartitions"
      expr  = "kafka_server_ReplicaManager_Value{job=\"msk-jmx-exporter\", name=\"UnderReplicatedPartitions\"} > 0"
      for   = "1m"
      labels = {
        severity = "critical"
      }
      annotations = {
        summary     = "[${var.msk_cluster_name}] MSK Broker has under-replicated partitions (instance {{ $labels.instance }})"
        description = "Broker {{ $labels.instance }} is reporting under-replicated partitions."
      }
    }
  ]

  topic_message_thresholds = {
    "cdc.trades.mnpi"         = 10000
    "cdc.orders.mnpi"         = 10000
    "cdc.positions.mnpi"      = 5000
    "cdc.market_data.public"  = 20000
    "cdc.reference_data.public" = 1000
  }

  topic_alert_rules = [
    for topic, threshold in local.topic_message_thresholds : {
      alert = "MSKTopicMessagesInHigh_${replace(topic, ".", "_")}"
      expr  = "sum by (topic, instance) (kafka_server_BrokerTopicMetrics_MeanRate{job=\"msk-jmx-exporter\", name=\"MessagesInPerSec\", topic=\"${topic}\"}) > ${threshold}"
      for   = "5m"
      labels = {
        severity = "warning"
        topic    = topic
      }
      annotations = {
        summary     = "[${var.msk_cluster_name}] High message rate for topic ${topic}"
        description = "The rate of messages for topic ${topic} is over ${threshold} msg/s."
      }
    }
  ]

  prometheus_rules_yaml = yamlencode({
    groups = [
      {
        name  = "msk-broker-alerts"
        rules = local.broker_alert_rules
      },
      {
        name  = "msk-topic-alerts"
        rules = local.topic_alert_rules
      }
    ]
  })

  # =============================================================================
  # Alertmanager Configuration (参考你以前的设置)
  # =============================================================================

  alertmanager_config_content = <<-EOT
    global:
      pagerduty_url: "https://events.pagerduty.com/v2/enqueue"
    
    route:
      receiver: 'pagerduty-warning'
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
        - match:
            severity: critical
          receiver: 'pagerduty-critical'

    receivers:
      - name: 'pagerduty-warning'
        pagerduty_configs:
          - service_key: "${var.pagerduty_integration_key_warning}"
            description: "{{ .CommonAnnotations.summary }}"

      - name: 'pagerduty-critical'
        pagerduty_configs:
          - service_key: "${var.pagerduty_integration_key_critical}"
            description: "{{ .CommonAnnotations.summary }}"
  EOT
}

# =============================================================================
# SSM Parameters for Image Tags
# =============================================================================

data "aws_ssm_parameter" "schema_registry_image_tag" {
  name = "/${var.app_name}/${var.env}/schema-registry/image-tag"
}

data "aws_ssm_parameter" "cruise_control_image_tag" {
  name = "/${var.app_name}/${var.env}/cruise-control/image-tag"
}

data "aws_ssm_parameter" "prometheus_image_tag" {
  name = "/${var.app_name}/${var.env}/prometheus/image-tag"
}

data "aws_ssm_parameter" "alertmanager_image_tag" {
  name = "/${var.app_name}/${var.env}/alertmanager/image-tag"
}
