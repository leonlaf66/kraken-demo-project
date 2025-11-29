# =============================================================================
# Kafka Module Outputs
# =============================================================================

output "kafka_topics" {
  description = "Created Kafka topics"
  value       = module.kafka.topic_names
}

output "kafka_topic_count" {
  description = "Number of topics created"
  value       = module.kafka.topic_count
}

output "kafka_acl_summary" {
  description = "Summary of ACLs by user"
  value       = module.kafka.acl_summary
}

output "kafka_users" {
  description = "Users with ACL permissions"
  value       = module.kafka.users_with_acls
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers endpoint"
  value       = module.kafka.bootstrap_servers
}

# =============================================================================
# MSK Connect Outputs
# =============================================================================

output "debezium_connector_arn" {
  description = "ARN of the Debezium CDC connector"
  value       = module.debezium_cdc_source.connector_arn
}

output "s3_sink_mnpi_connector_arn" {
  description = "ARN of the S3 Sink MNPI connector"
  value       = module.s3_sink_mnpi.connector_arn
}

output "s3_sink_public_connector_arn" {
  description = "ARN of the S3 Sink Public connector"
  value       = module.s3_sink_public.connector_arn
}
