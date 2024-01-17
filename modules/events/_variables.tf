variable "ddb_source_type" {
  type        = string
  default     = "db-cluster"
  description = "The type of source that will be generating the events. Valid options are db-instance, db-cluster, db-parameter-group, db-security-group,db-cluster-snapshot. If not set, all sources will be subscribed to."
}
variable "ddb_source_ids" {
  type        = list(string)
  default     = []
  description = "A list of identifiers of the event sources for which events will be returned. If not specified, then all sources are included in the response. If specified, a source_type must also be specified."
}
variable "ddb_event_categories" {
  type        = list(string)
  default     = []
  description = "A list of event categories for a SourceType that you want to subscribe to. See https://docs.aws.amazon.com/documentdb/latest/developerguide/API_Event.html or run `aws docdb describe-event-categories`"
}

variable "sns_topic_arn" {
  type        = string
  default     = ""
  description = "Provide sns topic arn if `create_sns_notification=false`."
}

variable "enable_sns_notification" {
  type        = bool
  default     = true
  description = "Enable sns notification."
}
