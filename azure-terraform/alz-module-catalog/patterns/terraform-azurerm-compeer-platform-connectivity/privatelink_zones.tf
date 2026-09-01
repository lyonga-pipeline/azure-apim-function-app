# =============================================================================
# Canonical Azure Private Link DNS zone catalogue
#
# deploy-runbook.tf §7.4: "Use a map(object(...)) catalogue... Only create zones
# actually needed by platform/workloads. Do not create every known Azure
# privatelink zone preemptively."
#
# Set var.privatelink_zone_catalogue to a list of SHORT keys (below) to add
# those zones to var.private_dns_zones. Everything merges - hand-authored
# private_dns_zones entries still work and win on key collision.
#
# Region-templated zones ({region}) are expanded with var.privatelink_zone_region
# (default = var.location); multi-token services (monitor) add all sub-zones.
# =============================================================================

locals {
  effective_private_dns_zones = merge(local.privatelink_zones, var.private_dns_zones)
}

locals {
  _plz_region = coalesce(try(var.privatelink_zone_region, null), var.location)

  # short key -> zone name(s). One entry may expand to several zones.
  _plz_all = {
    blob              = ["privatelink.blob.core.windows.net"]
    blob_secondary    = ["privatelink.blob.core.windows.net"]
    file              = ["privatelink.file.core.windows.net"]
    queue             = ["privatelink.queue.core.windows.net"]
    table             = ["privatelink.table.core.windows.net"]
    dfs               = ["privatelink.dfs.core.windows.net"]
    web_storage       = ["privatelink.web.core.windows.net"]
    keyvault          = ["privatelink.vaultcore.azure.net"]
    keyvault_hsm      = ["privatelink.managedhsm.azure.net"]
    app_service       = ["privatelink.azurewebsites.net"]
    app_config        = ["privatelink.azconfig.io"]
    sql               = ["privatelink.database.windows.net"]
    sql_mi            = ["privatelink.${local._plz_region}.database.windows.net"]
    synapse_sql       = ["privatelink.sql.azuresynapse.net"]
    synapse_dev       = ["privatelink.dev.azuresynapse.net"]
    postgres          = ["privatelink.postgres.database.azure.com"]
    mysql             = ["privatelink.mysql.database.azure.com"]
    mariadb           = ["privatelink.mariadb.database.azure.com"]
    redis             = ["privatelink.redis.cache.windows.net"]
    redis_enterprise  = ["privatelink.redisenterprise.cache.azure.net"]
    cosmos_sql        = ["privatelink.documents.azure.com"]
    cosmos_mongo      = ["privatelink.mongo.cosmos.azure.com"]
    cosmos_cassandra  = ["privatelink.cassandra.cosmos.azure.com"]
    cosmos_gremlin    = ["privatelink.gremlin.cosmos.azure.com"]
    cosmos_table      = ["privatelink.table.cosmos.azure.com"]
    servicebus        = ["privatelink.servicebus.windows.net"]
    eventhub          = ["privatelink.servicebus.windows.net"]
    eventgrid         = ["privatelink.eventgrid.azure.net"]
    acr               = ["privatelink.azurecr.io"]
    aks               = ["privatelink.${local._plz_region}.azmk8s.io"]
    monitor           = ["privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.blob.core.windows.net"]
    automation        = ["privatelink.azure-automation.net"]
    cognitiveservices = ["privatelink.cognitiveservices.azure.com"]
    openai            = ["privatelink.openai.azure.com"]
    search            = ["privatelink.search.windows.net"]
    signalr           = ["privatelink.service.signalr.net"]
    batch             = ["privatelink.${local._plz_region}.batch.azure.com"]
    datafactory       = ["privatelink.datafactory.azure.net", "privatelink.adf.azure.com"]
    databricks        = ["privatelink.azuredatabricks.net"]
    backup            = ["privatelink.${local._plz_region}.backup.windowsazure.com"]
    site_recovery     = ["privatelink.siterecovery.windowsazure.com"]
    grafana           = ["privatelink.grafana.azure.com"]
    hdinsight         = ["privatelink.azurehdinsight.net"]
    iothub            = ["privatelink.azure-devices.net", "privatelink.servicebus.windows.net"]
    machinelearning   = ["privatelink.api.azureml.ms", "privatelink.notebooks.azure.net"]
  }

  _plz_selected = distinct(flatten([
    for key in try(var.privatelink_zone_catalogue, []) : lookup(local._plz_all, key, [])
  ]))

  # zone name -> catalogue entry, deduplicated on zone name.
  privatelink_zones = {
    for name in local._plz_selected : replace(replace(name, "privatelink.", ""), ".", "_") => {
      name                 = name
      link_to_hub          = true
      registration_enabled = false
    }
  }
}
