output "id" {
  value       = try(aws_docdb_event_subscription.ddb_event_subscription[0].id, "")
  description = "Name of the DocumentDB event notification subscription."
}

output "arn" {
  value       = try(aws_docdb_event_subscription.ddb_event_subscription[0].arn, "")
  description = "Amazon Resource Name (ARN) of the DocumentDB event notification subscription."
}

output "sns_topic_arn" {
  value = module.context.enabled && local.enable_sns_notification ? try(module.sns[0].topic_arn, "") : ""
  description = "Amazon Resource Name (ARN) of SNS topic."
}