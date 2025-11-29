data "aws_vpc" "selected" {
  tags = {
    Name = "kraken-vpc-${var.env}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Storage Module

module "storage" {
  source = "../../../tfm/modules/storage"

  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = var.common_tags
}


# Database Module

module "database" {
  source = "../../../tfm/modules/database"

  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = var.common_tags

  vpc_id         = data.aws_vpc.main.id
  db_subnet_ids  = data.aws_subnets.private.ids
  allowed_ingress_cidrs = [data.aws_vpc.main.cidr_block]

  db_name           = "kraken_db"
  db_engine_version = "14.7"
  db_instance_class = "db.t3.medium"
  
  db_allocated_storage     = 20
  db_max_allocated_storage = 100
  db_storage_type          = "gp3"

  db_username = "postgres"
  db_multi_az = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false
}

# msk Module

module "msk" {
  source = "../../../tfm/modules/msk"
  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = var.common_tags

  vpc_id             = data.aws_vpc.slected.id
  vpc_cidr           = data.aws_vpc.slected.cidr_block
  private_subnets    = data.aws_subnets.private.ids
  
  private_hosted_zone_id = var.create_route53_record

  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3
  instance_type          = "kafka.m5.large"
  ebs_volume_size        = 2000
  provisioned_throughput = 250

  enable_iam  = false
  scram_users = local.scram_users

  server_properties = {
    "auto.create.topics.enable"  = "false"
    "delete.topic.enable"        = "true"
    "default.replication.factor" = "3"
    "min.insync.replicas"        = "2"
    "num.io.threads"             = "8"
    "num.network.threads"        = "5"
    "num.partitions"             = "3"
    "num.replica.fetchers"       = "2"
    "log.retention.ms"           = "604800000"
    "log.segment.bytes"          = "1073741824"
    "compression.type"           = "producer" 
  }
}