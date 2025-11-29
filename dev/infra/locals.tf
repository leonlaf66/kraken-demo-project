# =============================================================================
# Locals
# =============================================================================

locals {
  scram_users = toset([
    "admin",
    "debezium",
    "s3_sink_mnpi",
    "s3_sink_public",
  ])
}

# =============================================================================
# Data Sources
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  tags = {
    Name = "kraken-vpc-${var.env}"
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
