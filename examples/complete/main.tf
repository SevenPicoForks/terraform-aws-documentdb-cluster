/*
Useful references:

https://docs.aws.amazon.com/documentdb/latest/developerguide/db-instance-classes.html#db-instance-class-specs
https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-parameter-group-create.html
https://www.terraform.io/docs/providers/aws/r/docdb_cluster.html
https://www.terraform.io/docs/providers/aws/r/docdb_cluster_instance.html
https://www.terraform.io/docs/providers/aws/r/docdb_cluster_parameter_group.html
https://www.terraform.io/docs/providers/aws/r/docdb_subnet_group.html
https://docs.aws.amazon.com/documentdb/latest/developerguide/troubleshooting.html
*/
module "documentdb_cluster" {
  source                          = "../../"
  cluster_size                    = var.cluster_size
  master_username                 = var.master_username
  master_password                 = var.master_password
  instance_class                  = var.instance_class
  db_port                         = var.db_port
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.subnets.private_subnet_ids
  apply_immediately               = var.apply_immediately
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  allowed_security_groups         = var.allowed_security_groups
  allowed_cidr_blocks             = var.allowed_cidr_blocks
  snapshot_identifier             = var.snapshot_identifier
  retention_period                = var.retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  cluster_parameters              = var.cluster_parameters
  cluster_family                  = var.cluster_family
  engine                          = var.engine
  engine_version                  = var.engine_version
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  skip_final_snapshot             = var.skip_final_snapshot
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  cluster_dns_name                = var.cluster_dns_name
  reader_dns_name                 = var.reader_dns_name
  zone_id                         = try(aws_route53_zone.private[0].id, "")

  context = module.context.self
}

module "ddb_event_subscription_cluster" {
  source     = "../../modules/events"
  context    = module.context.self
  attributes = ["creation"]

  ddb_event_categories = ["creation"]
  ddb_source_ids       = [module.documentdb_cluster.id]
  ddb_source_type      = "db-cluster"
  sns_topic_arn        = null
}

module "ddb_event_subscription_cluster" {
  source     = "../../modules/events"
  context    = module.context.self
  attributes = ["failure", "failover"]

  ddb_event_categories = ["failure", "failover"]
  ddb_source_ids       = [module.documentdb_cluster.id]
  ddb_source_type      = "db-cluster"
  sns_topic_arn        = null
}

module "sns" {
  count             = module.context.enabled ? 1: 0
  source            = "SevenPico/sns/aws"
  version           = "2.0.2"
  context           = module.context.self
  kms_master_key_id = ""
  pub_principals    = {}
  sub_principals    = {}
}

module "ddb_event_subscription_instance" {
  source     = "../../modules/events"
  context    = module.context.self
  attributes = ["cluster","instance"]

  ddb_event_categories = ["failure", "failover"]
  ddb_source_ids       = [module.documentdb_cluster.instance_identifier]
  ddb_source_type      = "db-instance"
  sns_topic_arn        = module.sns.topic_arn
}
