/**  
*  # Azure Event Grid
*   This is the base module for creating event grid topic and event subscription. 
*   This module does not create `System Topic` or `Domain Topic`. 
*  
*  
*   # Module Usage
*   ```hcl
*   module "eventgrid" {
*     source = "../"
*     
*     eventgrid_topic_name = "test-topic-compeer"
*     resource_group_name = "demo-rg"
*     public_network_access_enabled = false
*     eventgrid_subscription = [{
*        "name": "function-subscription"
*        "event_delivery_schema": "EventGridSchema"
*        "azure_function_endpoint": {
*           "function_id": "<Azure function ID, Required parameter>"
*           "max_events_per_batch": "<Optional paramater>"
*           "preferred_batch_size_in_kilobytes": "<Optional value>"
*        }
*        "storage_queue_endpoint": {
*           "storage_account_id": "<Id of the storage account, Required parameter>"
*           "queue_name": "<Storage account Queue name, Required parameter>"
*        }
*        "webhook_endpoint": {
*           "url": "<URL to watch, Required parameter>"
*           "max_events_per_batch": "<Optional parameter>"
*           "preferred_batch_size_in_kilobytes": "<Optional parameter>"
*           "active_directory_tenant_id": "<Optional parameter>"
*           "active_directory_app_id_or_uri": "<Optional parameter>"
*        }
*        "eventhub_endpoint_id": "<(Optional) Specifies the id where the Event Hub is located.>"
*        "hybrid_connection_endpoint_id": "<(Optional) Specifies the id where the Hybrid Connection is located.>"
*        "service_bus_queue_endpoint_id": "<Optional) Specifies the id where the Service Bus Queue is located.>"
*        "service_bus_topic_endpoint_id": "<(Optional) Specifies the id where the Service Bus Topic is located.>"
*     }]
*  }
*   ``` 
*  
*   **Note**: For the variable `eventgrid_subscription` you are allowed to use anyone parameter, 
*   Example: When you want to use `webhook_endpoint` paramater, other paramaters should have `null` value to it, except for `name` and `event_delivery_schema`. 
*  
*/
