#------------------------------------------------------------------------------
# Sns
#------------------------------------------------------------------------------}
module "sns" {
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.context.self
  enabled = module.context.enabled && var.enable_sns_notification

  kms_master_key_id = var.kms_key_id
  pub_principals = {
    "ddbpubpermission" = {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"] // This should be replaced with the actual service or ARN you're intending to allow.
      condition = {
        test     = "StringEquals"
        variable = "AWS:SourceOwner"
        values   = ["${local.arn_prefix}:rds:${local.region}:${local.account_id}:*:*"]
      }
    }
  }
  sub_principals = {}
}


#------------------------------------------------------------------------------
# DDB Event Subscription
#------------------------------------------------------------------------------
resource "aws_docdb_event_subscription" "ddb_events_subscription" {
  count            = module.context.enabled && var.enable_sns_notification ? 1 : 0
  name             = "${module.context.id}-ddb-event-subscription"
  enabled          = true
  event_categories = var.ddb_event_categories
  source_type      = var.ddb_source_type
  source_ids       = var.ddb_source_ids
  sns_topic_arn    = var.enable_sns_notification ? module.sns.topic_arn : var.sns_topic_arn
  tags             = module.context.tags
}