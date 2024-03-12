#------------------------------------------------------------------------------
# Lambda
#------------------------------------------------------------------------------
locals {
  sns_topic_arns = [
    module.ddb_event_subscription_cluster_creation.sns_topic_arn
  ]

  sns_topic_arns_map = { for idx, topic_arn in local.sns_topic_arns : idx => topic_arn }
}

data "aws_iam_policy_document" "lambda_role_policy_doc" {
  count = module.context.enabled ? 1 : 0

  policy_id = module.context.id

  statement {
    sid     = "AllowPub"
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [
      try(aws_sns_topic.sns_chatbot[0].arn, "")
    ]
  }
}

data "archive_file" "lambda_zip" {
  count       = module.context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/notification-transformer"
  output_path = "${path.module}/lambda/notification-transformer.zip"
}

module "lambda" {
  source  = "registry.terraform.io/SevenPicoForks/lambda-function/aws"
  version = "2.0.3"
  context = module.context.self
  enabled = module.context.enabled

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = ""
  cloudwatch_logs_retention_in_days   = 90
  cloudwatch_log_subscription_filters = {}
  description                         = "Lambda function to send custom message to chatbot"
  event_source_mappings               = {}
  filename                            = try(data.archive_file.lambda_zip[0].output_path, null)
  source_code_hash                    = try(filebase64sha256(data.archive_file.lambda_zip[0].output_path), "")
  file_system_config                  = null
  function_name                       = module.context.id
  handler                             = "index.handler"
  ignore_external_function_updates    = false
  image_config                        = {}
  image_uri                           = null
  kms_key_arn                         = ""
  lambda_at_edge                      = false
  lambda_environment = {
    variables = {
      REGION : local.region
      SNS_TOPIC_ARN : try(aws_sns_topic.sns_chatbot[0].arn, "")
      ACCOUNT_ID : local.account_id
      DEPLOYMENT_ENVIRONMENT : module.context.environment
    }
  }
  lambda_role_source_policy_documents = []
  layers                              = []
  memory_size                         = 512
  package_type                        = "Zip"
  publish                             = false
  reserved_concurrent_executions      = -1
  role_name                           = "${module.context.id}-lambda-role"
  runtime                             = "nodejs18.x"
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  ssm_parameter_names                 = null
  timeout                             = 300
  tracing_config_mode                 = null
  vpc_config                          = null
}

resource "aws_lambda_permission" "ddb_events_sns_permission" {
  for_each      = module.context.enabled ? local.sns_topic_arns_map : {}
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = each.value
}

resource "aws_sns_topic_subscription" "ddb_events_sns_subscription" {
  for_each  = module.context.enabled ? local.sns_topic_arns_map : {}
  topic_arn = each.value
  protocol  = "lambda"
  endpoint  = module.lambda.arn
}

resource "aws_iam_policy" "lambda_role_policy" {
  count       = module.context.enabled ? 1 : 0
  name        = "${module.context.id}-sns-permission-policy"
  description = "Permission To Allow Lambda to Publish To Sns & Decrypt kms Key."
  policy      = data.aws_iam_policy_document.lambda_role_policy_doc[0].json
}

resource "aws_iam_policy_attachment" "lambda_role_policy_attachment" {
  count      = module.context.enabled ? 1 : 0
  name       = "${module.context.id}-policy-attachment"
  roles      = ["${module.context.id}-lambda-role"]
  policy_arn = aws_iam_policy.lambda_role_policy[0].arn
}

