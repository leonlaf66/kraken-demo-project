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

**Data Pipeline:**
```
                         Schema Registry
                      (schema management)
                              │
                              ▼
PostgreSQL ──▶ Debezium ──▶ MSK ──▶ S3 Sink ──▶ S3 Data Lake ◀── Athena
   (RDS)     (msk-connect)  (msk)  (msk-connect)   (storage)     (athena)
                                                        │
                                                        ▼
                                                  Glue Catalog
                                                   (metadata)
```

**Platform Services (ECS Fargate):**
```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ Schema Registry │  Cruise Control │   Prometheus    │  Alertmanager   │
│ (schema mgmt)   │ (cluster mgmt)  │  (metrics)      │   (alerting)    │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

**Data Isolation:**
```
MNPI Zone (sensitive)              Public Zone (non-sensitive)
├── cdc.*.mnpi (topics)            ├── cdc.*.public (topics)
├── raw_mnpi (S3)                  ├── raw_public (S3)
├── curated_mnpi (S3)              ├── curated_public (S3)
├── analytics_mnpi (S3)            ├── analytics_public (S3)
└── KMS: kms_mnpi                  └── KMS: kms_public
```

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
