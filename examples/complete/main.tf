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
  source                     = "../../"
  allowed_cidr_blocks        = []
  allowed_security_groups    = []
  apply_immediately          = true
  auto_minor_version_upgrade = true
  cluster_dns_name           = ""
  cluster_family             = var.cluster_family
  cluster_parameters = [{
    apply_method = "pending-reboot"
    name         = "tls"
    value        = "enabled"
  }]
  cluster_size                    = var.cluster_size
  db_port                         = var.db_port
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = []
  engine                          = var.engine
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  kms_key_id                      = ""
  master_password                 = var.master_password
  master_username                 = var.master_username
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  reader_dns_name                 = ""
  retention_period                = var.retention_period
  skip_final_snapshot             = var.skip_final_snapshot
  snapshot_identifier             = ""
  storage_encrypted               = var.storage_encrypted
  subnet_ids                      = module.vpc_subnets.private_subnet_ids
  vpc_id                          = module.vpc.vpc_id
  zone_id                         = ""
  enable_performance_insights     = false
  performance_insights_kms_key_id = ""
}

module "ddb_event_subscription_cluster" {
  source = "../../modules/events"

  ddb_event_categories = ["creation", "failure", "failover"]
  ddb_source_ids       = [module.documentdb_cluster.id]
  ddb_source_type      = "db-cluster"
  sns_topic_arn        = null
}

module "ddb_event_subscription_instance" {
  source = "../../modules/events"

  ddb_event_categories = ["creation", "failure", "failover"]
  ddb_source_ids       = [module.documentdb_cluster.id]
  ddb_source_type      = "db-instance"
  sns_topic_arn        = null
}
