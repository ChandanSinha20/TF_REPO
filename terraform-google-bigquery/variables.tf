variable "datasets" {}

variable "default_table_expiration_hr" {
  description = "(optional) The default lifetime of all tables in the dataset, in hours"
  type        = string
  default     = null
}

variable "default_partition_expiration_ms" {
  description = "(Optional) The dafault partition expiration for all partitioned table in the dataset, in milliseconds"
  type        = string
  default     = null
}

variable "description" {
  description = "Dataset description"
  type        = string
  default     = null

}

variable "region" {
  description = "The regional location for the dataset only US and EU are allowed in module"
  type        = string
}
variable "project_id" {
  description = "Project where the datset and tables are created"
  type        = string
}

variable "kms_key" {
  description = "Ecnryption key to apply to the dataset."
  type        = string
  default     = ""

}

variable "labels" {
  description = "A map of custom labels to apply to the instance. The key in the label name and the value is the label name."
  type        = map(any)
  validation {
    condition = alltrue([
      for t in ["gbgf", "owner", "entity", "service", "region", "user", "resource-repo"] : contains(keys(var.labels), t)
    ])
    error_message = "Please include all mandatory tags [gbgf,owner,entity,service,region,user,resource-repo]."
  }
}
variable "delete_contents_on_destroy" {
  description = "(Optional)If set to true, delete all the tables in the dataset when destroying the resource; otherwise, destroying the resources will fail if tables are present."
  type        = bool
  default     = false

}

variable "dataset_id_modifier" {
  description = "how to modeify dataset_id, upper, lower or none"
  type        = string
  default     = "upper"

}

variable "tables" {
  description = "A list of objects which include table_id, table_name, schema, clustering, time_partitioning, range_partitioning, expiration_time and labels."
  default     = []
  type = list(object({
    table_id                 = string,
    description              = optional(string),
    table_name               = optional(string),
    schema                   = string,
    clustering               = optional(list(string), []),
    require_partition_filter = optional(bool),
    time_partitioning = optional(object({
      expiration_ms = string,
      field         = string,
      type          = string,
    }), null),
    range_partitioning = optional(object({
      field = string,
      range = object({
        start    = string,
        end      = string,
        interval = string,
      })
    }), null),
    expiration_time     = optional(string, null),
    deletion_protection = optional(bool),
    labels              = optional(map(string), {}),

  }))
}

variable "storage_billing_model" {
  description = "specifies the storage billing model for the dataset. set this flag value to use LOGICAL to use logical bytes for storage billing, or to physical bytes instead. LOGICAL is the default if this flag isn't speicifed."
  type        = string
  default     = null

}

variable "sensitive_params" {
  type = map(object({
    secret_access_key = string
  }))
  default = {}
}
variable "email_preferences" {
  type = map(object({
    enable_failure_email = bool
  }))
  default = {}

}

variable "schedule_options" {
  type = map(object({
    disable_auto_scheduling = bool
    start_time              = string
    end_time                = string
  }))
  default = {}

}

variable "params" {
  description = "parameter specific to each data source"
  type        = map(any)
  default     = {}

}

variable "service_account_name" {
  description = "Bigquery scheduled query display name"
  type        = string
  default     = null

}

variable "display_name" {
  description = "Bigquery scheduled query display name"
  type        = string
  default     = null

}

variable "data_source_id" {
  description = "Data source ID"
  type        = string
  default     = "scheduled_query"
}

variable "destination_dataset_id" {
  description = "Destination table name"
  type        = string
  default     = null
}
variable "data_refresh_window_days" {
  description = "The number of days to look back to automatically refresh the data"
  type        = string
  default     = null
}

variable "schedule" {
  description = "schedule for the query"
  type        = string
  default     = null

}

variable "disabled" {
  description = "the number of days to look back to automatically refresh the data"
  type        = string
  default     = null
}
variable "notification_pubsub_topic" {
  description = "pubsub topic name for notification"
  type        = string
  default     = null
}