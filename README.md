# Kraken Demo Project

Terraform configurations for deploying the Kraken Data Lake platform.

## Stack Structure

```
dev/
├── infra/          # Infrastructure layer (runs first)
│   ├── storage.tf      # S3 Data Lake, Glue, CloudTrail
│   ├── database.tf     # PostgreSQL RDS
│   └── msk.tf          # MSK Cluster
│
└── data-plane/     # Data plane layer (depends on infra)
    ├── kafka.tf            # Topics & ACLs
    ├── msk_connect.tf      # Debezium, S3 Sink connectors
    ├── streaming_services.tf  # Schema Registry, Prometheus, etc.
    ├── athena.tf           # Query layer
    └── ingress.tf          # Security group rules
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         Kraken Data Lake Platform                                        │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                                    Platform Services (ECS Fargate)                                  │ │
│  │                                                                                                     │ │
│  │   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐            │ │
│  │   │ Schema Registry │   │ Cruise Control  │   │   Prometheus    │   │  Alertmanager   │            │ │
│  │   │  (port 8081)    │   │  (port 9090)    │   │   (port 9090)   │   │   (port 9093)   │            │ │
│  │   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘   └─────────────────┘            │ │
│  │            │ schema              │ rebalance           │ metrics                                   │ │
│  │            │ validation          │ partitions          │ collection                                │ │
│  │            ▼                     ▼                     ▼                                           │ │
│  └────────────┼─────────────────────┼─────────────────────┼───────────────────────────────────────────┘ │
│               │                     │                     │                                             │
│  ┌────────────┼─────────────────────┼─────────────────────┼───────────────────────────────────────────┐ │
│  │            │                     │                     │              Streaming Layer              │ │
│  │            │                     ▼                     │                                           │ │
│  │            │            ┌─────────────────┐            │                                           │ │
│  │            └───────────▶│   MSK Cluster   │◀───────────┘                                           │ │
│  │                         │  (SCRAM Auth)   │                                                        │ │
│  │                         │   ┌─────────────────────────────────────┐                                │ │
│  │                         │   │            Topics                   │                                │ │
│  │                         │   │  ┌───────────┐    ┌───────────┐     │                                │ │
│  │                         │   │  │ cdc.*.mnpi│    │cdc.*.public│    │                                │ │
│  │                         │   │  └───────────┘    └───────────┘     │                                │ │
│  │                         │   └─────────────────────────────────────┘                                │ │
│  │                         └───────────┬─────────────────┬───────────┘                                │ │
│  │                                     │                 │                                            │ │
│  │                                     ▼                 ▼                                            │ │
│  │  ┌─────────────────┐       ┌─────────────────┐ ┌─────────────────┐                                 │ │
│  │  │    Debezium     │──────▶│  S3 Sink MNPI   │ │ S3 Sink Public  │                                 │ │
│  │  │  (CDC Source)   │ CDC   │  (MSK Connect)  │ │  (MSK Connect)  │                                 │ │
│  │  │  (MSK Connect)  │       └────────┬────────┘ └────────┬────────┘                                 │ │
│  │  └────────▲────────┘                │                   │                                          │ │
│  │           │                         │                   │                                          │ │
│  └───────────┼─────────────────────────┼───────────────────┼──────────────────────────────────────────┘ │
│              │ CDC                     │                   │                                            │
│              │                         ▼                   ▼                                            │
│  ┌───────────┴───────┐       ┌─────────────────────────────────────────────────────────────────────┐   │
│  │    PostgreSQL     │       │                      S3 Data Lake (storage)                         │   │
│  │      (RDS)        │       │                                                                     │   │
│  │                   │       │   ┌─────────────────────────┐   ┌─────────────────────────┐         │   │
│  │ ┌───────────────┐ │       │   │      MNPI Zone          │   │     Public Zone         │         │   │
│  │ │ trades        │ │       │   │   (KMS: kms_mnpi)       │   │  (KMS: kms_public)      │         │   │
│  │ │ orders        │ │       │   │                         │   │                         │         │   │
│  │ │ positions     │ │       │   │  ┌─────────────────┐    │   │  ┌─────────────────┐    │         │   │
│  │ │ market_data   │ │       │   │  │ raw_mnpi        │    │   │  │ raw_public      │    │         │   │
│  │ │ reference_data│ │       │   │  │ curated_mnpi    │    │   │  │ curated_public  │    │         │   │
│  │ └───────────────┘ │       │   │  │ analytics_mnpi  │    │   │  │ analytics_public│    │         │   │
│  └───────────────────┘       │   │  └─────────────────┘    │   │  └─────────────────┘    │         │   │
│                              │   └─────────────────────────┘   └─────────────────────────┘         │   │
│                              │                                                                     │   │
│                              └──────────────────────────────┬──────────────────────────────────────┘   │
│                                                             │                                          │
│  ┌──────────────────────────────────────────────────────────┼──────────────────────────────────────┐   │
│  │                                   Query Layer            │                                      │   │
│  │                                                          ▼                                      │   │
│  │                                                 ┌─────────────────┐                             │   │
│  │                                                 │  Glue Catalog   │                             │   │
│  │                                                 │   (metadata)    │                             │   │
│  │                                                 └────────┬────────┘                             │   │
│  │                                                          │ schema                               │   │
│  │   ┌─────────────────┐   ┌─────────────────┐   ┌─────────▼────────┐                             │   │
│  │   │Finance Analysts │   │  Data Analysts  │   │     Athena       │                             │   │
│  │   │ (MNPI+Public)   │──▶│  (Public only)  │──▶│  (Query Engine)  │                             │   │
│  │   │  MFA Required   │   │                 │   │                  │                             │   │
│  │   └─────────────────┘   └─────────────────┘   └──────────────────┘                             │   │
│  │                                                          │                                      │   │
│  │   ┌─────────────────┐                                    │ query                                │   │
│  │   │ Data Engineers  │────────────────────────────────────┘                                      │   │
│  │   │ (All Layers)    │                                                                           │   │
│  │   │  MFA Required   │                                                                           │   │
│  │   └─────────────────┘                                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. **PostgreSQL → Debezium**: CDC captures row-level changes from source tables
2. **Debezium → MSK**: Publish CDC events to Kafka topics (MNPI/Public separated by topic name)
3. **MSK → S3 Sink**: Write events to S3 raw layer buckets (partitioned by `year/month/day/hour`)
4. **S3 ← Glue Catalog**: Glue stores table metadata and schema information
5. **Athena → S3**: Query engine reads data directly from S3, using Glue for metadata

**Platform Services (ECS Fargate):**
- **Schema Registry**: Schema versioning and compatibility validation
- **Cruise Control**: MSK cluster rebalancing and partition management
- **Prometheus + Alertmanager**: Metrics collection and alerting

## Spacelift Configuration

### Context Variables (Shared)

Create a Spacelift Context with the following environment variables:

| Environment Variable | Description | Example |
|---------------------|-------------|---------|
| `TF_VAR_env` | Environment name | `dev` |
| `TF_VAR_aws_region` | AWS region | `us-east-1` |
| `TF_VAR_aws_account_id` | AWS Account ID | `123456789012` |
| `TF_VAR_iam_permissions_boundary_arn` | IAM permissions boundary | `arn:aws:iam::123456789012:policy/BoundaryPolicy` |
| `TF_VAR_route53_private_zone_id` | Private hosted zone ID | `Z1234567890ABC` |

### Stack Dependencies

```
infra ──────▶ data-plane
```

### Required Inputs (infra)

| Variable | Source | Description |
|----------|--------|-------------|
| `env` | Context | Environment name |
| `aws_region` | Context | AWS region |
| `aws_account_id` | Context | AWS Account ID |
| `iam_permissions_boundary_arn` | Context | Permissions boundary for IAM roles |
| `route53_private_zone_id` | Context | Private hosted zone (optional) |

### Required Inputs (data-plane)

**From Spacelift Context:** Same as infra stack.

**From Infra Stack Outputs (via Spacelift Stack Dependencies):**

| Variable | Infra Output |
|----------|--------------|
| `msk_cluster_arn` | `msk_cluster_arn` |
| `msk_cluster_name` | `msk_cluster_name` |
| `msk_bootstrap_brokers_nlb` | `msk_bootstrap_brokers_nlb` |
| `msk_kms_key_arn` | `msk_kms_key_arn` |
| `msk_scram_secret_names` | `msk_scram_secret_names` |
| `msk_security_group_id` | `msk_security_group_id` |
| `database_master_secret_name` | `database_master_secret_name` |
| `database_security_group_id` | `database_security_group_id` |
| `bucket_raw_mnpi_arn` | `bucket_raw_mnpi_arn` |
| `bucket_raw_public_arn` | `bucket_raw_public_arn` |
| `bucket_curated_*_arn` | `bucket_curated_*_arn` |
| `bucket_analytics_*_arn` | `bucket_analytics_*_arn` |
| `kms_key_mnpi_arn` | `kms_key_mnpi_arn` |
| `kms_key_public_arn` | `kms_key_public_arn` |
| `glue_database_*` | `glue_database_*` |

**Additional Stack Variables:**

| Variable | Description |
|----------|-------------|
| `plugin_bucket_arn` | S3 bucket ARN containing MSK Connect plugins |
| `debezium_plugin_arn` | Debezium custom plugin ARN |
| `s3_sink_plugin_arn` | S3 Sink custom plugin ARN |
| `acm_certificate_arn` | ACM certificate ARN for HTTPS |

## Deployment

1. Create Spacelift Context with shared variables
2. Create `kraken-demo-dev-infra` stack, attach context
3. Create `kraken-demo-dev-data-plane` stack with dependency on infra, attach same context
4. Configure data-plane stack to receive outputs from infra
5. Trigger runs

## User Access Tiers

| Role | MNPI Access | Data Layers | MFA Required |
|------|-------------|-------------|--------------|
| Finance Analysts | Yes | analytics | Yes |
| Data Analysts | No | analytics | No |
| Data Engineers | Yes | raw, curated, analytics | Yes |

## Related Repositories

- [kraken-demo-module](https://github.com/leonlaf66/kraken-demo-module) - Terraform modules
