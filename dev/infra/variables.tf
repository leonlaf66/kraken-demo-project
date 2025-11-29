variable "app_name" {
  type        = string
  description = "Application name"
  default     = "kraken-demo"
}


variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "account_id" {
  type        = string
  description = "The AWS Account ID"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
}