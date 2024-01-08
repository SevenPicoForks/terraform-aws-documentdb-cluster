#------------------------------------------------------------------------------
# Sns Kms Key
#------------------------------------------------------------------------------
module "sns_kms_key" {
  source                   = "SevenPicoForks/kms-key/aws"
  version                  = "2.0.0"
  context                  = module.context.self
  enabled                  = module.context.enabled && var.create_sns_notification
  alias                    = ""
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false
}


#------------------------------------------------------------------------------
# Sns
#------------------------------------------------------------------------------
module "sns" {
  source            = "SevenPico/sns/aws"
  version           = "2.0.2"
  context           = module.context.self
  enabled           = module.context.enabled && var.create_sns_notification

  kms_master_key_id = module.sns_kms_key.key_id
  pub_principals    = {}
  sub_principals    = {}
}


#------------------------------------------------------------------------------
# DDB Event Subscription
#------------------------------------------------------------------------------
resource "aws_docdb_event_subscription" "ddb_event_subscription" {
  count            = module.context.enabled ? 1 : 0
  name             = "${module.context.id}-events"
  enabled          = true
  event_categories = var.ddb_event_categories
  source_type      = var.ddb_source_type
  source_ids       = var.ddb_source_ids
  sns_topic_arn    = var.create_sns_notification ? module.sns.topic_arn : var.sns_topic_arn
  tags             = module.context.tags
}