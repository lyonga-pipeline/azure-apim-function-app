module "eventgrid" {
  source = "../"

  eventgrid_topic_name          = "test-topic-presidio"
  resource_group_name           = "demo-rg"
  public_network_access_enabled = false
  eventgrid_subscription = [{
    "name" : "function-subscription"
    "event_delivery_schema" : "EventGridSchema"
    "azure_function_endpoint" : null
    "storage_queue_endpoint" : {
      "storage_account_id" : "/subscriptions/145ccdc1-6c51-4e45-a04e-21bdea03d170/resourceGroups/demo-rg/providers/Microsoft.Storage/storageAccounts/presidiocomp"
      "queue_name" : "testqueue"
    }
    },
    {
      "name" : "storage-subscription"
      "event_delivery_schema" : "EventGridSchema"
      "azure_function_endpoint" : null
      "storage_queue_endpoint" : {
        "storage_account_id" : "/subscriptions/145ccdc1-6c51-4e45-a04e-21bdea03d170/resourceGroups/demo-rg/providers/Microsoft.Storage/storageAccounts/presidiocomp"
        "queue_name" : "testqueue"
      }
  }]
}