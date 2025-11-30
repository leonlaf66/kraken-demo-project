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

### Stack Dependencies

```
infra ──────▶ data-plane
```

### Required Inputs (infra)

| Variable | Description |
|----------|-------------|
| env | Environment name |
| route53_private_zone_id | Private hosted zone (optional) |

### Required Inputs (data-plane)

Received from infra stack outputs:
- MSK: cluster_arn, bootstrap_brokers, security_group_id, scram_secret_names
- Database: master_secret_name, security_group_id  
- Storage: bucket ARNs, KMS keys, Glue databases

Additional inputs:
- plugin_bucket_arn, debezium_plugin_arn, s3_sink_plugin_arn
- acm_certificate_arn, route53_private_zone_id
- pagerduty_integration_key_* (optional)

## Deployment

### Via Spacelift
1. Create `kraken-demo-dev-infra` stack
2. Create `kraken-demo-dev-data-plane` stack with dependency on infra
3. Configure input variables from infra outputs
4. Trigger runs

### Local Testing
```bash
cd dev/infra
terraform init
terraform plan -var="env=dev"

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
