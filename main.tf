resource "aws_security_group" "default" {
  count       = module.context.enabled ? 1 : 0
  name        = module.context.id
  description = "Security Group for DocumentDB cluster"
  vpc_id      = var.vpc_id
  tags        = module.context.tags
}

resource "aws_security_group_rule" "egress" {
  count             = module.context.enabled ? 1 : 0
  type              = "egress"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "ingress_security_groups" {
  for_each                 = module.context.enabled ? toset(var.allowed_security_groups) : toset([])
  type                     = "ingress"
  description              = "Allow inbound traffic from existing Security Groups"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  type              = "ingress"
  count             = module.context.enabled && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  description       = "Allow inbound traffic from CIDR blocks"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = join("", aws_security_group.default.*.id)
}

resource "random_password" "password" {
  count   = module.context.enabled ? 1 : 0
  length  = 16
  special = false
}

resource "aws_docdb_cluster" "default" {
  count                           = module.context.enabled ? 1 : 0
  cluster_identifier              = module.context.id
  master_username                 = var.master_username
  master_password                 = var.master_password != "" ? var.master_password : random_password.password[0].result
  backup_retention_period         = var.retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  final_snapshot_identifier       = lower(module.context.id)
  skip_final_snapshot             = var.skip_final_snapshot
  deletion_protection             = var.deletion_protection
  apply_immediately               = var.apply_immediately
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  port                            = var.db_port
  snapshot_identifier             = var.snapshot_identifier
  vpc_security_group_ids          = [join("", aws_security_group.default.*.id)]
  db_subnet_group_name            = join("", aws_docdb_subnet_group.default.*.name)
  db_cluster_parameter_group_name = join("", aws_docdb_cluster_parameter_group.default.*.name)
  engine                          = var.engine
  engine_version                  = var.engine_version
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  tags                            = module.context.tags


}

resource "aws_docdb_cluster_instance" "default" {
  count                      = module.context.enabled ? var.cluster_size : 0
  identifier                 = "${module.context.id}-${count.index + 1}"
  cluster_identifier         = join("", aws_docdb_cluster.default.*.id)
  apply_immediately          = var.apply_immediately
  instance_class             = var.instance_class
  engine                     = var.engine
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  tags                       = module.context.tags
}

resource "aws_docdb_subnet_group" "default" {
  count       = module.context.enabled ? 1 : 0
  name        = module.context.id
  description = "Allowed subnets for DB cluster instances"
  subnet_ids  = var.subnet_ids
  tags        = module.context.tags
}

# https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-parameter-group-create.html
resource "aws_docdb_cluster_parameter_group" "default" {
  count       = module.context.enabled ? 1 : 0
  name        = module.context.id
  description = "DB cluster parameter group"
  family      = var.cluster_family

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  tags = module.context.tags
}

locals {
  cluster_dns_name_default  = "master.${module.context.name}"
  cluster_dns_name          = var.cluster_dns_name != "" ? var.cluster_dns_name : local.cluster_dns_name_default
  replicas_dns_name_default = "replicas.${module.context.name}"
  replicas_dns_name         = var.reader_dns_name != "" ? var.reader_dns_name : local.replicas_dns_name_default
}

module "dns_master" {
  source  = "cloudposse/route53-cluster-hostname/aws"
  version = "0.12.2"

  enabled  = module.context.enabled
  dns_name = local.cluster_dns_name
  zone_id  = var.zone_id
  records  = coalescelist(aws_docdb_cluster.default.*.endpoint, [""])

  context = module.context.legacy
}

module "dns_replicas" {
  source  = "cloudposse/route53-cluster-hostname/aws"
  version = "0.12.2"

  enabled  = module.context.enabled
  dns_name = local.replicas_dns_name
  zone_id  = var.zone_id
  records  = coalescelist(aws_docdb_cluster.default.*.reader_endpoint, [""])

  context = module.context.legacy
}
