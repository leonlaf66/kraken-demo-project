module "msk" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk?ref=v1.0.0"

  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = local.common_tags

  vpc_id          = data.aws_vpc.selected.id
  vpc_cidr        = data.aws_vpc.selected.cidr_block
  private_subnets = data.aws_subnets.private.ids

  private_hosted_zone_id = var.route53_private_zone_id

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
