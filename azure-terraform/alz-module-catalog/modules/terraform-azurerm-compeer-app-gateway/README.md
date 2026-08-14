# Azure Application gateway
Azure Application Gateway provides HTTP based load balancing that enables in creating routing rules for traffic based on HTTP.
This terraform module quickly creates a desired application gateway with additional options like WAF, Custom Error Configuration, SSL offloading with SSL policies, URL path mapping and many other options.

## Module Usage
```hcl
  module "application-gateway" {
     source = "../"

     # By default, this module will not create a resource group and expect to provide
     # a existing RG name to use an existing resource group. Location will be same as existing RG.
     # set the argument to `create_resource_group = true` to create new resrouce.
     resource_group_name    = "demo-rg" # FIX ME, change to correct resource-group
     virtual_network_name   = "demo-vnet" # FIX ME, change to correct Virtual network name
     app_gateway_subnet     = "APPGW" # FIX ME, change to correct Subnet name
     app_gateway_name       = "testgateway"
     public_ip_config_name  = "public_frontend_ip_config"
     private_ip_config_name = "private_frontend_ip_config"
     private_ip_address     = "10.0.2.10"

     # SKU requires `name`, `tier` to use for this Application Gateway
     # `Capacity` property is optional if `autoscale_configuration` is set
     sku = {
        name     = "Standard_v2"
        tier     = "Standard_v2"
        capacity = 1
     }

     # A backend pool routes request to backend servers, which serve the request.
     # Can create different backend pools for different types of requests
     backend_address_pools = [
        {
           name  = "appgw-testgateway-eastus-bapool01"
           fqdns = ["example1.com", "example2.com"]
        },
        {
           name         = "appgw-testgateway-eastus-bapool02"
           ip_addresses = ["1.2.3.4", "2.3.4.5"]
        }
     ]

     # An application gateway routes traffic to the backend servers using the port, protocol, and other settings
     # The port and protocol used to check traffic is encrypted between the application gateway and backend servers
     # List of backend HTTP settings can be added here.  
     # `probe_name` argument is required if you are defing health probes.
     backend_http_settings = [
        {
           name                  = "appgw-testgateway-eastus-be-http-set1"
           cookie_based_affinity = "Disabled"
           path                  = "/"
           enable_https          = false
           request_timeout       = 30
           # probe_name            = "appgw-testgateway-eastus-probe1" # Remove this if `health_probes` object is not defined.
           connection_draining = {
           enable_connection_draining = true
           drain_timeout_sec          = 300

           }
        },
        {
           name                  = "appgw-testgateway-eastus-be-http-set2"
           cookie_based_affinity = "Enabled"
           path                  = "/"
           enable_https          = false
           request_timeout       = 30
        }
     ]

     # List of HTTP/HTTPS listeners. SSL Certificate name is required
     # `Basic` - This type of listener listens to a single domain site, where it has a single DNS mapping to the IP address of the
     # application gateway. This listener configuration is required when you host a single site behind an application gateway.
     # `Multi-site` - This listener configuration is required when you want to configure routing based on host name or domain name for
     # more than one web application on the same application gateway. Each website can be directed to its own backend pool.
     # Setting `host_name` value changes Listener Type to 'Multi site`. `host_names` allows special wildcard charcters.
     http_listeners = [
        {
           name                           = "appgw-testgateway-eastus-be-htln01"
           host_name                      = null
           frontend_ip_configuration_name = "public_frontend_ip_config"
        }
     ]

     # Request routing rule is to determine how to route traffic on the listener.
     # The rule binds the listener, the back-end server pool, and the backend HTTP settings.
     # `Basic` - All requests on the associated listener (for example, blog.contoso.com/*) are forwarded to the associated
     # backend pool by using the associated HTTP setting.
     # `Path-based` - This routing rule lets you route the requests on the associated listener to a specific backend pool,
     # based on the URL in the request.
     request_routing_rules = [
        {
           name                       = "appgw-testgateway-eastus-be-rqrt"
           rule_type                  = "Basic"
           http_listener_name         = "appgw-testgateway-eastus-be-htln01"
           backend_address_pool_name  = "appgw-testgateway-eastus-bapool01"
           backend_http_settings_name = "appgw-testgateway-eastus-be-http-set1"
           priority                   = 100
        }
     ]

     # A list with a single user managed identity id to be assigned to access Keyvault
     identity_ids = ["${azurerm_user_assigned_identity.example.id}"]

     # (Optional) To enable Azure Monitoring for Azure Application Gateway
     # (Optional) Specify `storage_account_name` to save monitoring logs to storage.
     # log_analytics_workspace_name = "loganalytics-we-sharedtest2"

    # Adding TAG's to Azure resources
    tags = {
       ProjectName  = "demo-internal"
       Env          = "dev"
       Owner        = "user@example.com"
       BusinessUnit = "CORP"
       ServiceClass = "Gold"
    }
 }
```

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
| [azurerm_application_gateway.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_monitor_diagnostic_setting.agw-diag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_log_analytics_workspace.logws](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_resource_group.info](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.storeacc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_gateway_name"></a> [app\_gateway\_name](#input\_app\_gateway\_name) | Name of the application gateway. | `string` | n/a | yes |
| <a name="input_backend_address_pools"></a> [backend\_address\_pools](#input\_backend\_address\_pools) | List of backend address pools | ```list(object({ name = string fqdns = optional(list(string)) ip_addresses = optional(list(string)) }))``` | n/a | yes |
| <a name="input_backend_http_settings"></a> [backend\_http\_settings](#input\_backend\_http\_settings) | List of backend HTTP settings. | ```list(object({ name = string cookie_based_affinity = string affinity_cookie_name = optional(string) path = optional(string) enable_https = bool probe_name = optional(string) request_timeout = number host_name = optional(string) pick_host_name_from_backend_address = optional(bool) authentication_certificate = optional(object({ name = string })) trusted_root_certificate_names = optional(list(string)) connection_draining = optional(object({ enable_connection_draining = bool drain_timeout_sec = number })) }))``` | n/a | yes |
| <a name="input_http_listeners"></a> [http\_listeners](#input\_http\_listeners) | List of HTTP/HTTPS listeners. SSL Certificate name is required | ```list(object({ name = string host_name = optional(string) host_names = optional(list(string)) require_sni = optional(bool) ssl_certificate_name = optional(string) firewall_policy_id = optional(string) ssl_profile_name = optional(string) frontend_ip_configuration_name = string # The name should match `private_ip_config_name` and `public_ip_config_name` custom_error_configuration = optional(list(object({ status_code = string custom_error_page_url = string }))) }))``` | n/a | yes |
| <a name="input_private_ip_config_name"></a> [private\_ip\_config\_name](#input\_private\_ip\_config\_name) | Name for the private IP configuration. | `string` | n/a | yes |
| <a name="input_public_ip_config_name"></a> [public\_ip\_config\_name](#input\_public\_ip\_config\_name) | Name for the public IP configuration. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name in which app-gateway should be deployed. | `string` | n/a | yes |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | VNET name for app gateway. | `string` | n/a | yes |
| <a name="input_agw_diag_logs"></a> [agw\_diag\_logs](#input\_agw\_diag\_logs) | Application Gateway Monitoring Category details for Azure Diagnostic setting | `list(string)` | ```[ "ApplicationGatewayAccessLog", "ApplicationGatewayPerformanceLog", "ApplicationGatewayFirewallLog" ]``` | no |
| <a name="input_app_gateway_subnet"></a> [app\_gateway\_subnet](#input\_app\_gateway\_subnet) | n/a | `string` | `"Subnet name to deploy the app gateway."` | no |
| <a name="input_authentication_certificates"></a> [authentication\_certificates](#input\_authentication\_certificates) | Authentication certificates to allow the backend with Azure Application Gateway | ```list(object({ name = string data = string }))``` | `[]` | no |
| <a name="input_autoscale_configuration"></a> [autoscale\_configuration](#input\_autoscale\_configuration) | Minimum or Maximum capacity for autoscaling. Accepted values are for Minimum in the range 0 to 100 and for Maximum in the range 2 to 125 | ```object({ min_capacity = number max_capacity = optional(number) })``` | `null` | no |
| <a name="input_custom_error_configuration"></a> [custom\_error\_configuration](#input\_custom\_error\_configuration) | Global level custom error configuration for application gateway | `list(map(string))` | `[]` | no |
| <a name="input_domain_name_label"></a> [domain\_name\_label](#input\_domain\_name\_label) | Label for the Domain Name. Will be used to make up the FQDN. | `any` | `null` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Is HTTP2 enabled on the application gateway resource? | `bool` | `false` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | The ID of the Web Application Firewall Policy which can be associated with app gateway | `string` | `null` | no |
| <a name="input_health_probes"></a> [health\_probes](#input\_health\_probes) | List of Health probes used to test backend pools health. | ```list(object({ name = string host = string interval = number path = string timeout = number unhealthy_threshold = number port = optional(number) pick_host_name_from_backend_http_settings = optional(bool) minimum_servers = optional(number) match = optional(object({ body = optional(string) status_code = optional(list(string)) })) }))``` | `[]` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list with a single user managed identity id to be assigned to the Application Gateway | `any` | `null` | no |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | The name of log analytics workspace name | `string` | `null` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | Private IP Address to assign to the Load Balancer. | `string` | `null` | no |
| <a name="input_redirect_configuration"></a> [redirect\_configuration](#input\_redirect\_configuration) | list of maps for redirect configurations | `list(map(string))` | `[]` | no |
| <a name="input_request_routing_rules"></a> [request\_routing\_rules](#input\_request\_routing\_rules) | List of Request routing rules to be used for listeners. | ```list(object({ name = string rule_type = string http_listener_name = string backend_address_pool_name = optional(string) backend_http_settings_name = optional(string) redirect_configuration_name = optional(string) rewrite_rule_set_name = optional(string) url_path_map_name = optional(string) priority = number }))``` | `[]` | no |
| <a name="input_rewrite_rule_set"></a> [rewrite\_rule\_set](#input\_rewrite\_rule\_set) | List of rewrite rule set including rewrite rules | `any` | `[]` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | The sku pricing model of v1 and v2 | ```object({ name = string # Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2 tier = string # Standard, Standard_v2, WAF and WAF_v2. capacity = optional(number) })``` | ```{ "name": "Standard_v2", "tier": "Standard_v2" }``` | no |
| <a name="input_ssl_certificates"></a> [ssl\_certificates](#input\_ssl\_certificates) | List of SSL certificates data for Application gateway | ```list(object({ name = string data = optional(string) password = optional(string) key_vault_secret_id = optional(string) }))``` | `[]` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Application Gateway SSL configuration | ```object({ disabled_protocols = optional(list(string)) policy_type = optional(string) policy_name = optional(string) cipher_suites = optional(list(string)) min_protocol_version = optional(string) })``` | `null` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the hub storage account to store logs | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_trusted_root_certificates"></a> [trusted\_root\_certificates](#input\_trusted\_root\_certificates) | Trusted root certificates to allow the backend with Azure Application Gateway | ```list(object({ name = string data = string }))``` | `[]` | no |
| <a name="input_url_path_maps"></a> [url\_path\_maps](#input\_url\_path\_maps) | List of URL path maps associated to path-based rules. | ```list(object({ name = string default_backend_http_settings_name = optional(string) default_backend_address_pool_name = optional(string) default_redirect_configuration_name = optional(string) default_rewrite_rule_set_name = optional(string) path_rules = list(object({ name = string backend_address_pool_name = optional(string) backend_http_settings_name = optional(string) paths = list(string) redirect_configuration_name = optional(string) rewrite_rule_set_name = optional(string) firewall_policy_id = optional(string) })) }))``` | `[]` | no |
| <a name="input_waf_configuration"></a> [waf\_configuration](#input\_waf\_configuration) | Web Application Firewall support for your Azure Application Gateway | ```object({ firewall_mode = string rule_set_version = string file_upload_limit_mb = optional(number) request_body_check = optional(bool) max_request_body_size_kb = optional(number) disabled_rule_group = optional(list(object({ rule_group_name = string rules = optional(list(string)) }))) exclusion = optional(list(object({ match_variable = string selector_match_operator = optional(string) selector = optional(string) }))) })``` | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A collection of availability zones to spread the Application Gateway over. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_gateway_id"></a> [application\_gateway\_id](#output\_application\_gateway\_id) | The ID of the Application Gateway |
| <a name="output_authentication_certificate_id"></a> [authentication\_certificate\_id](#output\_authentication\_certificate\_id) | The ID of the Authentication Certificate |
| <a name="output_backend_address_pool_id"></a> [backend\_address\_pool\_id](#output\_backend\_address\_pool\_id) | The ID of the Backend Address Pool |
| <a name="output_backend_http_settings_id"></a> [backend\_http\_settings\_id](#output\_backend\_http\_settings\_id) | The ID of the Backend HTTP Settings Configuration |
| <a name="output_backend_http_settings_probe_id"></a> [backend\_http\_settings\_probe\_id](#output\_backend\_http\_settings\_probe\_id) | The ID of the Backend HTTP Settings Configuration associated Probe |
| <a name="output_custom_error_configuration_id"></a> [custom\_error\_configuration\_id](#output\_custom\_error\_configuration\_id) | The ID of the Custom Error Configuration |
| <a name="output_frontend_ip_configuration_id"></a> [frontend\_ip\_configuration\_id](#output\_frontend\_ip\_configuration\_id) | The ID of the Frontend IP Configuration |
| <a name="output_frontend_port_id"></a> [frontend\_port\_id](#output\_frontend\_port\_id) | The ID of the Frontend Port |
| <a name="output_gateway_ip_configuration_id"></a> [gateway\_ip\_configuration\_id](#output\_gateway\_ip\_configuration\_id) | The ID of the Gateway IP Configuration |
| <a name="output_http_listener_frontend_ip_configuration_id"></a> [http\_listener\_frontend\_ip\_configuration\_id](#output\_http\_listener\_frontend\_ip\_configuration\_id) | The ID of the associated Frontend Configuration |
| <a name="output_http_listener_frontend_port_id"></a> [http\_listener\_frontend\_port\_id](#output\_http\_listener\_frontend\_port\_id) | The ID of the associated Frontend Port |
| <a name="output_http_listener_id"></a> [http\_listener\_id](#output\_http\_listener\_id) | The ID of the HTTP Listener |
| <a name="output_http_listener_ssl_certificate_id"></a> [http\_listener\_ssl\_certificate\_id](#output\_http\_listener\_ssl\_certificate\_id) | The ID of the associated SSL Certificate |
| <a name="output_probe_id"></a> [probe\_id](#output\_probe\_id) | The ID of the health Probe |
| <a name="output_redirect_configuration_id"></a> [redirect\_configuration\_id](#output\_redirect\_configuration\_id) | The ID of the Redirect Configuration |
| <a name="output_request_routing_rule_backend_address_pool_id"></a> [request\_routing\_rule\_backend\_address\_pool\_id](#output\_request\_routing\_rule\_backend\_address\_pool\_id) | The ID of the Request Routing Rule associated Backend Address Pool |
| <a name="output_request_routing_rule_backend_http_settings_id"></a> [request\_routing\_rule\_backend\_http\_settings\_id](#output\_request\_routing\_rule\_backend\_http\_settings\_id) | The ID of the Request Routing Rule associated Backend HTTP Settings Configuration |
| <a name="output_request_routing_rule_http_listener_id"></a> [request\_routing\_rule\_http\_listener\_id](#output\_request\_routing\_rule\_http\_listener\_id) | The ID of the Request Routing Rule associated HTTP Listener |
| <a name="output_request_routing_rule_id"></a> [request\_routing\_rule\_id](#output\_request\_routing\_rule\_id) | The ID of the Request Routing Rule |
| <a name="output_request_routing_rule_redirect_configuration_id"></a> [request\_routing\_rule\_redirect\_configuration\_id](#output\_request\_routing\_rule\_redirect\_configuration\_id) | The ID of the Request Routing Rule associated Redirect Configuration |
| <a name="output_request_routing_rule_rewrite_rule_set_id"></a> [request\_routing\_rule\_rewrite\_rule\_set\_id](#output\_request\_routing\_rule\_rewrite\_rule\_set\_id) | The ID of the Request Routing Rule associated Rewrite Rule Set |
| <a name="output_request_routing_rule_url_path_map_id"></a> [request\_routing\_rule\_url\_path\_map\_id](#output\_request\_routing\_rule\_url\_path\_map\_id) | The ID of the Request Routing Rule associated URL Path Map |
| <a name="output_rewrite_rule_set_id"></a> [rewrite\_rule\_set\_id](#output\_rewrite\_rule\_set\_id) | The ID of the Rewrite Rule Set |
| <a name="output_ssl_certificate_id"></a> [ssl\_certificate\_id](#output\_ssl\_certificate\_id) | The ID of the SSL Certificate |
| <a name="output_ssl_certificate_public_cert_data"></a> [ssl\_certificate\_public\_cert\_data](#output\_ssl\_certificate\_public\_cert\_data) | The Public Certificate Data associated with the SSL Certificate |
| <a name="output_url_path_map_default_backend_address_pool_id"></a> [url\_path\_map\_default\_backend\_address\_pool\_id](#output\_url\_path\_map\_default\_backend\_address\_pool\_id) | The ID of the Default Backend Address Pool associated with URL Path Map |
| <a name="output_url_path_map_default_backend_http_settings_id"></a> [url\_path\_map\_default\_backend\_http\_settings\_id](#output\_url\_path\_map\_default\_backend\_http\_settings\_id) | The ID of the Default Backend HTTP Settings Collection associated with URL Path Map |
| <a name="output_url_path_map_default_redirect_configuration_id"></a> [url\_path\_map\_default\_redirect\_configuration\_id](#output\_url\_path\_map\_default\_redirect\_configuration\_id) | The ID of the Default Redirect Configuration associated with URL Path Map |
| <a name="output_url_path_map_id"></a> [url\_path\_map\_id](#output\_url\_path\_map\_id) | The ID of the URL Path Map |
