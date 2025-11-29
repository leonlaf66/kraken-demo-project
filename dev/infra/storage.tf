module "storage" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//storage?ref=main"

  app_name    = var.app_name
  env         = var.env
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  common_tags = var.common_tags
}
