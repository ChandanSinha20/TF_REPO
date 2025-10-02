resource "google_bigquery_dataset" "main" {
  for_each                        = local.datasets
  dataset_id                      = lookup(each.value, "dataset_id")
  location                        = var.region
  description                     = var.description
  delete_contents_on_destroy      = var.delete_contents_on_destroy
  default_table_expiration_ms     = var.default_table_expiration_hr == null ? var.default_table_expiration_hr : var.default_table_expiration_hr * 3600000
  default_partition_expiration_ms = var.default_partition_expiration_ms == null ? var.default_partition_expiration_ms : var.default_partition_expiration_ms
  project                         = var.project_id
  storage_billing_model           = lookup(each.value, "storage_billing_model", var.storage_billing_model)
  default_encryption_configuration {
    kms_key_name = local.kms_key
  }
  labels = merge(local.default_labels, var.labels, lookup(each.value, "labels", {}), { name : substr(lower(lookup(each.value, "dataset_id")), 0, 63) })

  dynamic "access" {
    for_each = flatten([
      for l in lookup(each.value, "roles", {}) :
      {
        role           = lookup(l, "roles", "")
        user_by_email  = lookup(l, "user_by_email", "")
        group_by_email = lookup(l, "group_by_email", "")
        special_group  = lookup(l, "speific_group", "")
      }
    ])
    content {
      role           = lookup(access.value, "role", "")
      user_by_email  = lookup(access.value, "user_by_email", "")
      group_by_email = lookup(access.value, "group_by_email", "")
      special_group  = lookup(access.value, "special_group", "")
    }
  }
  dynamic "access" {
    for_each = flatten([
      for l in lookup(each.value, "views", {}) :
      {
        dataset_id = lookup(l, "dataset_id", "")
        project_id = lookup(l, "project_id", "")
        table_id   = lookup(l, "table_id", "")
      }
    ])
    content {
      view {
        dataset_id = lookup(access.value, "datset_id", "")
        project_id = lookup(access.value, "project_id", "")
        table_id   = lookup(access.value, "table_id", "")
      }
    }
  }
  dynamic "access" {
    for_each = flatten([
      for l in lookup(each.value, "dataset", {}) :
      {
        dataset_id = lookup(l, "dataset_id", "")
        project_id = lookup(l, "project_id", "")
      }
    ])
    content {
      dataset {
        dataset {
          project_id = access.value.project_id
          dataset_id = access.value.dataset_id
        }
        target_types = ["VIEWS"]
      }
    }

  }
}

resource "google_bigquery_table" "main" {
  for_each            = { for idx, val in local.tables : idx => val }
  dataset_id          = each.value["dataset_id"]
  table_id            = lookup(each.value, "table_id", "")
  schema              = lookup(each.value, "schema", "")
  project             = var.project_id
  deletion_protection = lookup(each.value, "deletion_protection", false)


  dynamic "view" {
    for_each = lookup(each.value, "query", "")
    content {
      query          = view.value
      use_legacy_sql = lookup(each.value, "use_legacy_sql", false)
    }
  }
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "kms_support") ? [1] : []
    content {
      kms_key_name = local.kms_key
    }
  }
  depends_on = [google_bigquery_dataset.main]

}

resource "google_bigquery_routine" "main" {
  for_each        = { for idx, val in local.sql_procedures : idx => val }
  project         = var.project_id
  dataset_id      = each.value["dataset_id"]
  routine_id      = lookup(each.value, "routine_id", "")
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = lookup(each.value, "definition_body", "")
  depends_on      = [google_bigquery_dataset.main, ]

}

resource "google_bigquery_data_transfer_config" "query_config" {
  count                     = length(var.params) > 0 ? 1 : 0
  project                   = var.project_id
  display_name              = var.display_name
  location                  = var.region
  service_account_name      = var.service_account_name
  data_source_id            = var.data_source_id
  schedule                  = var.schedule
  destination_dataset_id    = var.destination_dataset_id
  notification_pubsub_topic = var.notification_pubsub_topic
  data_refresh_window_days  = var.data_refresh_window_days
  disabled                  = var.disabled
  params                    = var.params
  dynamic "schedule_options" {
    for_each = var.schedule_options
    content {
      disable_auto_scheduling = lookup(schedule_options.value, "disable_auto_scheduling", null)
      start_time              = lookup(schedule_options.value, "start_time", null)
      end_time                = lookup(schedule_option.value, "end_time", null)
    }

  }
  dynamic "email_preferences" {
    for_each = var.email_preferences
    content {
      enable_failure_email = lookup(email_preferences.value, "enable_failure_email", false)
    }
  }
  dynamic "sensitive_params" {
    for_each = var.sensitive_params
    content {
      secret_access_key = lookup(sensitive_params.value, "secret_access_key", null)
    }
  }
  depends_on = [google_bigquery_dataset.main, google_bigquery_table.main]
}
