module "database" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//database?ref=main"

  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = var.common_tags

  # Network
  vpc_id                = data.aws_vpc.selected.id
  db_subnet_ids         = data.aws_subnets.private.ids
  allowed_ingress_cidrs = [data.aws_vpc.selected.cidr_block]

  # Database Configuration
  db_name           = "kraken_db"
  db_engine_version = "14.7"
  db_instance_class = "db.t3.medium"

  db_allocated_storage     = 20
  db_max_allocated_storage = 100
  db_storage_type          = "gp3"

  db_username = "postgres"
  db_multi_az = false

  # Backup & Maintenance
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false
}
