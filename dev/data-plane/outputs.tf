# MSK Connect Connectors
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

# Athena Workgroups
output "athena_workgroup_names" {
  description = "Athena workgroup names by user group"
  value       = { for k, v in module.athena.workgroups : k => v.name }
}

# Streaming Service URLs
output "schema_registry_url" {
  description = "Schema Registry endpoint URL"
  value       = local.schema_registry_url
}

output "cruise_control_url" {
  description = "Cruise Control endpoint URL"
  value       = module.streaming_services.service_endpoints["cruise-control"]
}

output "prometheus_url" {
  description = "Prometheus endpoint URL"
  value       = module.streaming_services.service_endpoints["prometheus"]
}

output "alertmanager_url" {
  description = "Alertmanager endpoint URL"
  value       = module.streaming_services.service_endpoints["alertmanager"]
}
