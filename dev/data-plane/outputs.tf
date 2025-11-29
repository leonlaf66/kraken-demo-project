# =============================================================================
# ECS Service Outputs
# =============================================================================

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.streaming_services.cluster_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.streaming_services.cluster_name
}

# Service ARNs
output "schema_registry_service_arn" {
  description = "Schema Registry ECS service ARN"
  value       = module.streaming_services.service_arns["schema-registry"]
}

output "cruise_control_service_arn" {
  description = "Cruise Control ECS service ARN"
  value       = module.streaming_services.service_arns["cruise-control"]
}

output "prometheus_service_arn" {
  description = "Prometheus ECS service ARN"
  value       = module.streaming_services.service_arns["prometheus"]
}

output "alertmanager_service_arn" {
  description = "Alertmanager ECS service ARN"
  value       = module.streaming_services.service_arns["alertmanager"]
}

# Service Endpoints (DNS)
output "schema_registry_endpoint" {
  description = "Schema Registry endpoint URL"
  value       = module.streaming_services.service_endpoints["schema-registry"]
}

output "cruise_control_endpoint" {
  description = "Cruise Control endpoint URL"
  value       = module.streaming_services.service_endpoints["cruise-control"]
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint URL"
  value       = module.streaming_services.service_endpoints["prometheus"]
}

output "alertmanager_endpoint" {
  description = "Alertmanager endpoint URL"
  value       = module.streaming_services.service_endpoints["alertmanager"]
}

# Schema Registry URL (for MSK Connect and other services)
output "schema_registry_url" {
  description = "Schema Registry URL for connector configuration"
  value       = local.schema_registry_url
}

# =============================================================================
# MSK Connect Outputs
# =============================================================================

output "debezium_connector_arn" {
  description = "Debezium CDC source connector ARN"
  value       = module.debezium_cdc_source.connector_arn
}

output "s3_sink_mnpi_connector_arn" {
  description = "S3 Sink MNPI connector ARN"
  value       = module.s3_sink_mnpi.connector_arn
}

output "s3_sink_public_connector_arn" {
  description = "S3 Sink Public connector ARN"
  value       = module.s3_sink_public.connector_arn
}

# =============================================================================
# Athena Outputs
# =============================================================================

output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.main.name
}

# =============================================================================
# Security Group Outputs
# =============================================================================

output "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  value       = module.streaming_services.ecs_tasks_security_group_id
}
