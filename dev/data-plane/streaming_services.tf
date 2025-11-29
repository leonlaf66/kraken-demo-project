################################################################################
# Streaming Services - ECS Module
################################################################################

module "streaming_services" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//ecs-service?ref=main"

  app_name       = local.app_name
  environment    = local.environment
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
  common_tags    = local.common_tags

  # Networking
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  # ECS Cluster
  cluster_name       = "${local.app_name}-${local.environment}-streaming"
  container_insights = true

  # HTTPS
  acm_certificate_arn = var.acm_certificate_arn

  # EFS
  efs_performance_mode = "generalPurpose"
  efs_throughput_mode  = "bursting"

  # Security - allow access from VPC
  alb_ingress_cidr_blocks = [local.vpc_cidr]

  # Allow MSK brokers to be scraped by Prometheus
  ecs_additional_ingress_security_group_ids = var.msk_security_group_ids

  # Services
  services = {
    #---------------------------------------------------------------------------
    # Schema Registry
    #---------------------------------------------------------------------------
    schema-registry = {
      image = local.schema_registry_image

      cpu    = 1024
      memory = 2048

      container_port    = 8081
      health_check_path = "/subjects"

      enable_alb        = true
      alb_listener_port = 8081

      enable_route53  = true
      route53_zone_id = var.route53_private_zone_id

      environment = [
        { name = "SCHEMA_REGISTRY_HOST_NAME", value = "0.0.0.0" },
        { name = "SCHEMA_REGISTRY_LISTENERS", value = "http://0.0.0.0:8081" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS", value = var.msk_bootstrap_brokers_nlb },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_SECURITY_PROTOCOL", value = "SASL_SSL" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_SASL_MECHANISM", value = "SCRAM-SHA-512" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM", value = "" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_TOPIC", value = "_schemas" },
        { name = "SCHEMA_REGISTRY_KAFKASTORE_TOPIC_REPLICATION_FACTOR", value = "2" },
        { name = "SCHEMA_REGISTRY_DEBUG", value = "false" },
      ]

      secrets = [
        {
          name      = "SCHEMA_REGISTRY_KAFKASTORE_SASL_JAAS_CONFIG"
          valueFrom = "${local.kafka_credentials_secret_arn}:sasl_jaas_config::"
        }
      ]

      container_health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/subjects || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }

    #---------------------------------------------------------------------------
    # Cruise Control (参考你以前的设置)
    #---------------------------------------------------------------------------
    cruise-control = {
      image = local.cruise_control_image

      cpu    = 1024
      memory = 4096

      container_port    = 9090
      health_check_path = "/kafkacruisecontrol/state"

      enable_alb        = true
      alb_listener_port = 9090

      enable_route53  = true
      route53_zone_id = var.route53_private_zone_id

      efs_volumes = {
        state = {
          container_path = "/opt/cruise-control/cruise-control-logs"
          read_only      = false
        }
        data = {
          container_path = "/opt/cruise-control/data"
          read_only      = false
        }
      }

      environment = [
        { name = "KAFKA_HEAP_OPTS", value = "-Xmx2g -Xms2g" },
        { name = "CC_UI_ENVIRONMENT", value = local.environment },
        { name = "APPLICATION_NAME", value = local.app_name },
        # Cruise Control properties
        { name = "BOOTSTRAP_SERVERS", value = local.msk_bootstrap_endpoint },
        { name = "SECURITY_PROTOCOL", value = "SASL_SSL" },
        { name = "SASL_MECHANISM", value = "SCRAM-SHA-512" },
        { name = "SSL_ENDPOINT_IDENTIFICATION_ALGORITHM", value = "" },
        # Capacity settings (参考你以前的设置)
        { name = "CAPACITY_DISK", value = "102400" },
        { name = "CAPACITY_CPU", value = "4" },
        { name = "CAPACITY_NW", value = "1562500" },
      ]

      secrets = [
        {
          name      = "SASL_JAAS_CONFIG"
          valueFrom = "${local.kafka_credentials_secret_arn}:sasl_jaas_config::"
        }
      ]

      container_health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9090/kafkacruisecontrol/state || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 120
      }
    }

    #---------------------------------------------------------------------------
    # Prometheus (参考你以前的设置)
    #---------------------------------------------------------------------------
    prometheus = {
      image = local.prometheus_image

      cpu    = 1024
      memory = 2048

      container_port    = 9090
      health_check_path = "/-/healthy"

      enable_alb        = true
      alb_listener_port = 9091 # Different port to avoid conflict with cruise-control

      enable_route53  = true
      route53_zone_id = var.route53_private_zone_id

      efs_volumes = {
        data = {
          container_path = "/prometheus"
          read_only      = false
        }
        config = {
          container_path = "/etc/prometheus"
          read_only      = false
        }
      }

      environment = [
        { name = "PROMETHEUS_RETENTION_TIME", value = "15d" },
        { name = "PROMETHEUS_RETENTION_SIZE", value = "10GB" },
      ]

      # Command args for Prometheus
      command = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--storage.tsdb.retention.time=15d",
        "--web.enable-lifecycle"
      ]

      container_health_check = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }

    #---------------------------------------------------------------------------
    # Alertmanager (参考你以前的设置)
    #---------------------------------------------------------------------------
    alertmanager = {
      image = local.alertmanager_image

      cpu    = 256
      memory = 512

      container_port    = 9093
      health_check_path = "/-/healthy"

      enable_alb        = true
      alb_listener_port = 9093

      enable_route53  = true
      route53_zone_id = var.route53_private_zone_id

      efs_volumes = {
        data = {
          container_path = "/alertmanager"
          read_only      = false
        }
      }

      environment = [
        { name = "ALERTMANAGER_CLUSTER_PEER", value = "" },
      ]

      command = [
        "--config.file=/etc/alertmanager/alertmanager.yml",
        "--storage.path=/alertmanager",
        "--cluster.listen-address="
      ]

      container_health_check = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9093/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  }
}

################################################################################
# SSM Parameters for Configuration
################################################################################

# Prometheus config
resource "aws_ssm_parameter" "prometheus_config" {
  name  = "/${var.app_name}/${var.env}/prometheus/config"
  type  = "String"
  value = local.prometheus_config_content

  tags = local.common_tags
}

# Prometheus alert rules
resource "aws_ssm_parameter" "prometheus_rules" {
  name  = "/${var.app_name}/${var.env}/prometheus/rules"
  type  = "String"
  value = local.prometheus_rules_yaml

  tags = local.common_tags
}

# Alertmanager config
resource "aws_ssm_parameter" "alertmanager_config" {
  name  = "/${var.app_name}/${var.env}/alertmanager/config"
  type  = "SecureString"
  value = local.alertmanager_config_content

  tags = local.common_tags
}

# Cruise Control properties
resource "aws_ssm_parameter" "cruise_control_config" {
  name  = "/${var.app_name}/${var.env}/cruise-control/config"
  type  = "SecureString"
  value = jsonencode(local.cruise_control_properties)

  tags = local.common_tags
}
