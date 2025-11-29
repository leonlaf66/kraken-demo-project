module "sg_ingress" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//sg_ingress?ref=main"

  ingress_rules = {
    # RDS
    "rds-from-debezium" = {
      description                  = "PostgreSQL from Debezium CDC connector"
      security_group_id            = var.rds_security_group_id
      referenced_security_group_id = module.debezium_cdc_source.security_group_id
      from_port                    = 5432
      to_port                      = 5432
      ip_protocol                  = "tcp"
    }

    # MSK
    "msk-from-debezium" = {
      description                  = "Kafka SCRAM from Debezium CDC"
      security_group_id            = var.msk_security_group_id
      referenced_security_group_id = module.debezium_cdc_source.security_group_id
      from_port                    = 9096
      to_port                      = 9096
      ip_protocol                  = "tcp"
    }

    "msk-from-s3-sink-mnpi" = {
      description                  = "Kafka SCRAM from S3 Sink MNPI"
      security_group_id            = var.msk_security_group_id
      referenced_security_group_id = module.s3_sink_mnpi.security_group_id
      from_port                    = 9096
      to_port                      = 9096
      ip_protocol                  = "tcp"
    }

    "msk-from-s3-sink-public" = {
      description                  = "Kafka SCRAM from S3 Sink Public"
      security_group_id            = var.msk_security_group_id
      referenced_security_group_id = module.s3_sink_public.security_group_id
      from_port                    = 9096
      to_port                      = 9096
      ip_protocol                  = "tcp"
    }
  }
}