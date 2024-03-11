#------------------------------------------------------------------------------
# ChatBot Role
#------------------------------------------------------------------------------
module "chatbot_role" {
  source     = "SevenPicoForks/iam-role/aws"
  version    = "2.0.1"
  context    = module.context.self
  enabled    = module.context.enabled
  attributes = ["chatbot", "service", "role"]

  role_description         = "AWS ChatBot Assume role"
  assume_role_actions      = ["sts:AssumeRole"]
  assume_role_conditions   = []
  instance_profile_enabled = false
  managed_policy_arns      = []
  permissions_boundary     = ""
  policy_description       = ""
  policy_document_count    = 0
  policy_documents         = []
  principals = {
    "Service" : ["chatbot.amazonaws.com"]
  }
  path         = "/"
  use_fullname = true
  tenant       = ""
}


#------------------------------------------------------------------------------
# ChatBot
#------------------------------------------------------------------------------
resource "aws_sns_topic" "sns_chatbot" {
  count  = module.context.enabled ? 1 : 0
  name   = "${module.context.id}-notifications-chatbot"
}

resource "awscc_chatbot_slack_channel_configuration" "chatbot_slack" {
  count              = module.context.enabled ? 1 : 0
  configuration_name = "${module.context.id}-events-notification"
  iam_role_arn       = module.chatbot_role.arn
  logging_level      = "NONE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  sns_topic_arns = [
    try(aws_sns_topic.sns_chatbot[0].arn, "")
  ]
  user_role_required = false
}