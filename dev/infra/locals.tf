locals {
    scram_users = toset([
    "admin",
    "debezium",        # CDC Source: Write cdc.*, R/W schema-changes.*
    "s3_sink_mnpi",    # S3 Sink: Read *.mnpi topics
    "s3_sink_public",  # S3 Sink: Read *.public topics
  ])
}

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