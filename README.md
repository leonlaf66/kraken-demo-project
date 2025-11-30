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

## Spacelift Configuration

### Context Variables (Shared)

Create a Spacelift Context with the following environment variables. These are shared across both stacks:

| Environment Variable | Description | Example |
|---------------------|-------------|---------|
| `TF_VAR_env` | Environment name | `dev` |
| `TF_VAR_aws_region` | AWS region | `us-east-1` |
| `TF_VAR_aws_account_id` | AWS Account ID | `123456789012` |
| `TF_VAR_iam_permissions_boundary_arn` | IAM permissions boundary | `arn:aws:iam::123456789012:policy/BoundaryPolicy` |
| `TF_VAR_route53_private_zone_id` | Private hosted zone ID | `Z1234567890ABC` |

> **Note**: The stacks use `data.aws_caller_identity` and `data.aws_region` for runtime lookups, but explicit variables ensure consistency across Spacelift runs.

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

**From Spacelift Context:**

Same context variables as infra stack.

**From Infra Stack Outputs (Spacelift Stack Dependencies):**

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
| `bucket_raw_mnpi_id` | `bucket_raw_mnpi_id` |
| `bucket_raw_public_arn` | `bucket_raw_public_arn` |
| `bucket_raw_public_id` | `bucket_raw_public_id` |
| `bucket_curated_mnpi_arn` | `bucket_curated_mnpi_arn` |
| `bucket_curated_public_arn` | `bucket_curated_public_arn` |
| `bucket_analytics_mnpi_arn` | `bucket_analytics_mnpi_arn` |
| `bucket_analytics_public_arn` | `bucket_analytics_public_arn` |
| `kms_key_mnpi_arn` | `kms_key_mnpi_arn` |
| `kms_key_public_arn` | `kms_key_public_arn` |
| `glue_database_raw_mnpi` | `glue_database_raw_mnpi` |
| `glue_database_raw_public` | `glue_database_raw_public` |
| `glue_database_curated_mnpi` | `glue_database_curated_mnpi` |
| `glue_database_curated_public` | `glue_database_curated_public` |
| `glue_database_analytics_mnpi` | `glue_database_analytics_mnpi` |
| `glue_database_analytics_public` | `glue_database_analytics_public` |

**Additional Inputs (Stack Variables):**

| Variable | Description |
|----------|-------------|
| `plugin_bucket_arn` | S3 bucket ARN containing MSK Connect plugins |
| `debezium_plugin_arn` | Debezium custom plugin ARN |
| `s3_sink_plugin_arn` | S3 Sink custom plugin ARN |
| `acm_certificate_arn` | ACM certificate ARN for HTTPS |
| `pagerduty_integration_key_warning` | PagerDuty key (optional) |
| `pagerduty_integration_key_critical` | PagerDuty key (optional) |

## Deployment

### Via Spacelift

1. Create Spacelift Context with shared variables
2. Create `kraken-demo-dev-infra` stack, attach context
3. Create `kraken-demo-dev-data-plane` stack with dependency on infra, attach same context
4. Configure data-plane stack to receive outputs from infra
5. Trigger runs

### Local Testing

```bash
# Set environment variables (simulate Spacelift context)
export TF_VAR_env=dev
export TF_VAR_aws_region=us-east-1
export TF_VAR_aws_account_id=123456789012
export TF_VAR_iam_permissions_boundary_arn=arn:aws:iam::123456789012:policy/Boundary
export TF_VAR_route53_private_zone_id=Z1234567890ABC

# Infra stack
cd dev/infra
terraform init
terraform plan

# Data-plane stack (after infra is applied)
cd ../data-plane
terraform init
terraform plan -var-file="../../vars/dev.tfvars"
```

## Data Flow

```
                                    ┌─────────────────────────────────────────┐
                                    │          ECS Services                   │
                                    │  ┌───────────────┐  ┌───────────────┐   │
                                    │  │    Cruise     │  │  Prometheus   │   │
                                    │  │   Control     │  │ + Alertmanager│   │
                                    │  └───────┬───────┘  └───────┬───────┘   │
                                    │          │ manage           │ monitor   │
                                    │          ▼                  ▼           │
                                    │  ┌─────────────────────────────────┐    │
                                    │  │          MSK Cluster            │    │
                                    │  └─────────────────────────────────┘    │
                                    │                  ▲                      │
                                    │                  │                      │
                                    │  ┌───────────────┴───────────────┐      │
                                    │  │       Schema Registry         │      │
                                    │  └───────────────────────────────┘      │
                                    └──────────────────┬──────────────────────┘
                                                       │
                                              (register schema)
                                                       │
┌─────────────┐    ┌─────────────────────┐            │           ┌─────────────────────┐    ┌─────────────┐
│ PostgreSQL  │───▶│      Debezium       │────────────┴──────────▶│      S3 Sink        │───▶│  S3 Data    │
│   (RDS)     │CDC │  (MSK Connect)      │    MSK Topics          │   (MSK Connect)     │    │   Lake      │
└─────────────┘    └─────────────────────┘                        └─────────────────────┘    └──────┬──────┘
                                                                                                    │
                                                                                                    ▼
                                                                                            ┌───────────────┐
                                                                                            │ Glue Catalog  │
                                                                                            └───────┬───────┘
                                                                                                    │
                                                                                                    ▼
                                                                                            ┌───────────────┐
                                                                                            │    Athena     │
                                                                                            └───────────────┘
```

**Data Pipeline:**
1. **PostgreSQL → Debezium**: CDC captures row-level changes
2. **Debezium → Schema Registry**: Register/validate message schemas
3. **Debezium → MSK**: Publish CDC events to Kafka topics (MNPI/Public separated)
4. **MSK → S3 Sink**: Write events to S3 raw layer (partitioned by time)
5. **S3 → Glue → Athena**: Query data via SQL

**Platform Services (ECS):**
- **Schema Registry**: Schema versioning and compatibility for Kafka messages
- **Cruise Control**: MSK cluster rebalancing and optimization
- **Prometheus + Alertmanager**: Metrics collection and alerting

## User Access Tiers

| Role | MNPI | Layers | MFA |
|------|------|--------|-----|
| Finance Analysts | Yes | analytics | Required |
| Data Analysts | No | analytics | No |
| Data Engineers | Yes | all | Required |

## Related Repositories

- [kraken-demo-module](https://github.com/leonlaf66/kraken-demo-module) - Terraform modules
