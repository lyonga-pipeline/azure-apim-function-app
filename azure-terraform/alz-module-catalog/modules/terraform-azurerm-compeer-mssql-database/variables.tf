variable "name" {
  description = "The name of the Microsoft SQL Server. This needs to be globally unique within Azure."
  type        = string
}

variable "server_id" {
  description = "The id of the MS SQL Server on which to create the database. Changing this forces a new resource to be created."
  type        = string
}

variable "auto_pause_delay_in_minutes" {
  description = "Time in minutes after which database is automatically paused. A value of -1 means that automatic pause is disabled. This property is only settable for General Purpose Serverless databases."
  type        = number
  default     = -1
}

variable "create_mode" {
  description = "The create mode of the database."
  type        = string
  default     = null
}

variable "creation_source_database_id" {
  description = "The ID of the source database from which to create the new database. This should only be used for databases with create_mode values that use another database as reference. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "collation" {
  description = "Specifies the collation of the database. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "elastic_pool_id" {
  description = "Specifies the ID of the elastic pool containing this database."
  type        = string
  default     = null
}

variable "geo_backup_enabled" {
  description = "A boolean that specifies if the Geo Backup Policy is enabled. Defaults to true."
  type        = bool
  default     = null
}

variable "maintenance_configuration_name" {
  description = "The name of the Public Maintenance Configuration window to apply to the database."
  type        = string
  default     = null
}

variable "ledger_enabled" {
  description = "A boolean that specifies if this is a ledger database. Defaults to false. Changing this forces a new resource to be created."
  type        = bool
  default     = null
}

variable "license_type" {
  description = "Specifies the license type applied to this database."
  type        = string
  default     = null
}

variable "max_size_gb" {
  description = "The max size of the database in gigabytes."
  type        = number
  default     = null
}

variable "min_capacity" {
  description = "Minimal capacity that database will always have allocated, if not paused. This property is only settable for General Purpose Serverless databases."
  type        = number
  default     = null
}

variable "restore_point_in_time" {
  description = "Specifies the point in time (ISO8601 format) of the source database that will be restored to create the new database. This property is only settable for create_mode= PointInTimeRestore databases."
  type        = string
  default     = null
}

variable "recover_database_id" {
  description = "The ID of the database to be recovered. This property is only applicable when the create_mode is Recovery."
  type        = string
  default     = null
}

variable "restore_dropped_database_id" {
  description = "The ID of the database to be restored. This property is only applicable when the create_mode is Restore."
  type        = string
  default     = null
}

variable "read_replica_count" {
  description = "The number of readonly secondary replicas associated with the database to which readonly application intent connections may be routed. This property is only settable for Hyperscale edition databases."
  type        = number
  default     = null
}

variable "read_scale" {
  description = "If enabled, connections that have application intent set to readonly in their connection string may be routed to a readonly secondary replica. This property is only settable for Premium and Business Critical databases."
  type        = bool
  default     = null
}

variable "sample_name" {
  description = "Specifies the name of the sample schema to apply when creating this database."
  type        = string
  default     = null
}
variable "sku_name" {
  description = "Specifies the name of the SKU used by the database. For example, GP_S_Gen5_2,HS_Gen4_1,BC_Gen5_2, ElasticPool, Basic,S0, P2 ,DW100c, DS100. Changing this from the HyperScale service tier to another service tier will create a new resource."
  type        = string
  default     = null
}

variable "storage_account_type" {
  description = "Specifies the storage account type used to store backups for this database. Possible values are Geo, Local and Zone."
  type        = string
  default     = "Geo"
}

variable "transparent_data_encryption_enabled" {
  description = "If set to true, Transparent Data Encryption will be enabled on the database."
  type        = bool
  default     = null
}

variable "zone_redundant" {
  description = "Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones. This property is only settable for Premium and Business Critical databases."
  type        = bool
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "import" {
  description = " A Database Import block as documented below. Mutually exclusive with create_mode."
  type = object({
    storage_uri                  = string
    storage_key                  = string
    storage_key_type             = string
    administrator_login          = string
    administrator_login_password = string
    authentication_type          = string
    storage_account_id           = optional(string)
  })
  default = null
}

variable "long_term_retention_policy" {
  description = "A long_term_retention_policy block as defined below."
  type = object({
    weekly_retention  = optional(string)
    monthly_retention = optional(string)
    yearly_retention  = optional(string)
    week_of_year      = optional(string)
  })
  default = null
}

variable "short_term_retention_policy" {
  description = "A short_term_retention_policy block as defined below."
  type = object({
    retention_days           = number
    backup_interval_in_hours = optional(number)
  })
  default = null
}

variable "threat_detection_policy" {
  description = "Threat detection policy configuration. The threat_detection_policy block supports fields documented below."
  type = object({
    state                      = optional(string)
    disabled_alerts            = optional(list(string))
    email_account_admins       = optional(string)
    email_addresses            = optional(list(string))
    retention_days             = optional(number)
    storage_account_access_key = optional(string)
    storage_endpoint           = optional(string)
  })
  default = null
}
