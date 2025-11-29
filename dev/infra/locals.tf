locals {
    scram_users = toset([
    "admin",
    "debezium",        # CDC Source: Write cdc.*, R/W schema-changes.*
    "s3_sink_mnpi",    # S3 Sink: Read *.mnpi topics
    "s3_sink_public",  # S3 Sink: Read *.public topics
  ])
}