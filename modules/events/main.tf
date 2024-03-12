#------------------------------------------------------------------------------
# Sns
#------------------------------------------------------------------------------
resource "aws_sns_topic" "sns" { #FIXMe Use SevenPico/sns not using here because permission of sns mmodule needs to change
  count = module.context.enabled && var.enable_sns_notification ? 1 : 0
  name  = "${module.context.id}-sns"
  tags  = module.context.tags
}

data "aws_iam_policy_document" "sns_policy_document" {
  count = module.context.enabled && var.enable_sns_notification ? 1 : 0
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe",
    ]
    resources = [aws_sns_topic.sns[0].arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "PublishRdsEvents"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.sns[0].arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["${local.arn_prefix}:rds:${local.region}:${local.account_id}:*"]
    }
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  count  = module.context.enabled && var.enable_sns_notification ? 1 : 0
  arn    = aws_sns_topic.sns[0].arn
  policy = data.aws_iam_policy_document.sns_policy_document[0].json
}

#module "sns" {
#  source  = "SevenPico/sns/aws"
#  version = "2.0.2"
#  context = module.context.self
#  enabled = module.context.enabled && var.enable_sns_notification
#
#  kms_master_key_id = var.kms_key_id
#  pub_principals = {
#    "DocDbToPublish" = {
#      type        = "Service"
#      identifiers = ["rds.amazonaws.com"]
#      condition = {
#        test     = "StringEquals"
#        variable = "AWS:SourceOwner"
#        values   = ["${local.arn_prefix}:rds:${local.region}:${local.account_id}:*"]
#      }
#    }
#  }
#  sub_principals = {}
#}


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
  sns_topic_arn    = var.enable_sns_notification ? aws_sns_topic.sns[0].arn : var.sns_topic_arn
  tags             = module.context.tags
}