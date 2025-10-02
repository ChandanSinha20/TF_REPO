locals {
  environment = reverse(split("_".var.project_id))[0]
  eim         = regex("company-([0-9]+)-[a-z0-9]+-[a-z]+", var.project_id)[0]

  default_labels = {
    eim                 = local.eim
    project             = var.project_id
    environment         = local.environment
    lib_version         = lower(var.lib_version)
    git_repo            = lower(var.git_repo)
    tf_version          = lower(var.tf_version)
    data-classification = "restricted"
    component           = "bq_dataset"
  }

  datasets = { for k, v in var.datasets : coalesce(lookup(v, "index_key", ""), var.dataset_id_modifier == "upper" ? upper(k) : (var.dataset_id_modifier == "lower" ? lower(k) : k)) => merge(v, { "dataset_id" : var.dataset_id_modifier == "upper" ? upper(k) : (var.dataset_id_modifier == "lower" ? lower(k) : k) }) }
  tables = flatten([for key, value in local.datasets : [
    for i in lookup(value, "tables", []) :

    {
      dataset_id  = lookup(value, "dataset_id")
      table_id    = can(l.table_id) ? l.table_id : null
      schema      = can(l.schema) ? l.schema : null
      query       = can(l.query) ? [l.query] : []
      kms_support = can(l.query) ? false : true
      clustering  = optional(list(string), [])
      time_partitioning = optional(object({
        expiration_ms = string,
        field         = string,
        type          = string,
      }), null)
      use_legacy_sql      = can(l.use_legacy_sql) ? l.use_legacy_sql : false
      deletion_protection = can(l.deletion_protection) ? l.deletion_protection : false
    }
  ]])

  sql_procedures = flatten([for key, value in local.datasets : [
    for l in lookup(value, "sql_procedures", []) :
    {
      dataset_id      = lookup(value, "dataset_id")
      routine_id      = can(l.routine_id) ? l.routine_id : null
      definition_body = can(l.definition_body) ? l.definition_body : null
    }
  ]])

  iam_to_primitive = {
    "roles/bigquery.dataOwner" : "OWNER"
    "roles/bigquery.dataEditor" : "WRITER"
    "roles/bigquery.dataViewer" : "READER"
  }

  cmek_location_map = {
    eu = "europe"
  }
  kms_key = var.kms_key == "" ? "projects/company-kms-${local.environment}/locations/${lookup(local.cmek_location_map, var.region, var.region)}/keyRings/bigQuery/cryptoKeys/HSMbqShaerdKey" : var.kms_key












}
