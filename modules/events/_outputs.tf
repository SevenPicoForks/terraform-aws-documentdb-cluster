output "id" {
  value       = try(aws_docdb_event_subscription.ddb_events_subscription[0].id, "")
  description = "Name of the DocumentDB event notification subscription."
}

output "arn" {
  value       = try(aws_docdb_event_subscription.ddb_events_subscription[0].arn, "")
  description = "Amazon Resource Name (ARN) of the DocumentDB event notification subscription."
}

output "sns_topic_arn" {
  value       = try(module.sns.topic_arn, "")
  description = "Amazon Resource Name (ARN) of SNS topic."
}

output "kms_key_arn" {
  value       = try(module.sns_kms_key.key_arn, "")
  description = "Amazon Resource Name (ARN) of Kms key."
}

output "kms_key_id" {
  value       = try(module.sns_kms_key.key_id, "")
  description = "Kms Key id."
}