# Azure Event Grid System Topic
  This is the base module for creating event grid topic and event subscription.
  This module only creates `System Topic`.

# Module Usage
  ```hcl
  module "eventgrid" {
    source = "../"

    eventgrid_topic_name = "test-topic-compeer"
    resource_group_name = "demo-rg"
    public_network_access_enabled = false
    eventgrid_subscription = [{
       "name": "function-subscription"
       "event_delivery_schema": "EventGridSchema"
       "azure_function_endpoint": {
          "function_id": "<Azure function ID, Required parameter>"
          "max_events_per_batch": "<Optional paramater>"
          "preferred_batch_size_in_kilobytes": "<Optional value>"
       }
       "storage_queue_endpoint": {
          "storage_account_id": "<Id of the storage account, Required parameter>"
          "queue_name": "<Storage account Queue name, Required parameter>"
       }
       "webhook_endpoint": {
          "url": "<URL to watch, Required parameter>"
          "max_events_per_batch": "<Optional parameter>"
          "preferred_batch_size_in_kilobytes": "<Optional parameter>"
          "active_directory_tenant_id": "<Optional parameter>"
          "active_directory_app_id_or_uri": "<Optional parameter>"
       }
       "eventhub_endpoint_id": "<(Optional) Specifies the id where the Event Hub is located.>"
       "hybrid_connection_endpoint_id": "<(Optional) Specifies the id where the Hybrid Connection is located.>"
       "service_bus_queue_endpoint_id": "<Optional) Specifies the id where the Service Bus Queue is located.>"
       "service_bus_topic_endpoint_id": "<(Optional) Specifies the id where the Service Bus Topic is located.>"
    }]
 }

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.11, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.11, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_eventgrid_event_subscription.subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_event_subscription) | resource |
| [azurerm_eventgrid_system_topic.system_topic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_topic) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eventgrid_topic_name"></a> [eventgrid\_topic\_name](#input\_eventgrid\_topic\_name) | Specifies the name of the EventGrid Topic resource. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group. | `string` | n/a | yes |
| <a name="input_eventgrid_identity_ids"></a> [eventgrid\_identity\_ids](#input\_eventgrid\_identity\_ids) | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Event Grid Topic. | `list(string)` | `[]` | no |
| <a name="input_eventgrid_identity_type"></a> [eventgrid\_identity\_type](#input\_eventgrid\_identity\_type) | Specifies the type of Managed Service Identity that should be configured on this Event Grid Topic. | `string` | `"SystemAssigned"` | no |
| <a name="input_eventgrid_input_schema"></a> [eventgrid\_input\_schema](#input\_eventgrid\_input\_schema) | Specifies the schema in which incoming events will be published to this domain. Allowed values are `CloudEventSchemaV1_0`, `CustomEventSchema`, or `EventGridSchema` | `string` | `"EventGridSchema"` | no |
| <a name="input_eventgrid_subscription"></a> [eventgrid\_subscription](#input\_eventgrid\_subscription) | List of subscriptions to be subscribed to the . | ```list(object({ name = string event_delivery_schema = optional(string) azure_function_endpoint = optional(map(string)) storage_queue_endpoint = optional(map(string)) eventhub_endpoint_id = optional(string) hybrid_connection_endpoint_id = optional(string) service_bus_queue_endpoint_id = optional(string) service_bus_topic_endpoint_id = optional(string) webhook_endpoint = optional(map(string)) }))``` | `[]` | no |
| <a name="input_local_auth_enabled"></a> [local\_auth\_enabled](#input\_local\_auth\_enabled) | Whether local authentication methods is enabled for the EventGrid Topic. | `bool` | `true` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether or not public network access is allowed for this server. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventgrid_endpoint"></a> [eventgrid\_endpoint](#output\_eventgrid\_endpoint) | The Endpoint associated with the EventGrid Topic. |
| <a name="output_eventgrid_id"></a> [eventgrid\_id](#output\_eventgrid\_id) | The EventGrid Topic ID. |
| <a name="output_eventgrid_primary_access_key"></a> [eventgrid\_primary\_access\_key](#output\_eventgrid\_primary\_access\_key) | The Primary Shared Access Key associated with the EventGrid Topic. |
| <a name="output_eventgrid_secondary_access_key"></a> [eventgrid\_secondary\_access\_key](#output\_eventgrid\_secondary\_access\_key) | The Secondary Shared Access Key associated with the EventGrid Topic. |
| <a name="output_eventgrid_subscription_id"></a> [eventgrid\_subscription\_id](#output\_eventgrid\_subscription\_id) | Event grid subscription ID's |
