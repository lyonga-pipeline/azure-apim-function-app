variable "name" {
  description = "The name of the record. Modifying this attribute will force creation of a new resource."
  type        = string
}

variable "type" {
  description = "The type of the record."
  type        = string
  validation {
    condition     = can(index(["A", "AAAA", "CNAME", "TXT", "SPF", "PTR", "MX", "SRV", "LOC", "CAA", "CERT", "DNSKEY", "DS", "NAPTR", "SMIMEA", "SSHFP", "TLSA", "URI", "HTTPS", "SVCB"], var.type))
    error_message = "The record type is not valid."
  }
}

variable "zone_id" {
  description = "The zone identifier to target for the resource. Modifying this attribute will force creation of a new resource."
  type        = string
}

variable "allow_overwrite" {
  description = <<EOT
  "Allow creation of this record in Terraform to overwrite an existing record, 
  if any. This does not affect the ability to update the record in Terraform 
  and does not prevent other resources within Terraform or manual changes 
  outside Terraform from overwriting this record. 
  This configuration is not recommended for most environments. Defaults to false."
  EOT
  type        = bool
  default     = null
}

variable "comment" {
  description = "Comments or notes about the DNS record. This field has no effect on DNS responses."
  type        = string
  default     = null
}

variable "priority" {
  description = "The priority of the record"
  type        = number
  default     = null
}

variable "proxied" {
  description = "Whether the record gets Cloudflare's origin protection."
  type        = bool
  default     = null
}

variable "tags" {
  description = "Custom tags for DNS record"
  type        = set(string)
  default     = []
}

variable "ttl" {
  description = "The TTL of the record."
  type        = number
  default     = null
}

variable "value" {
  description = "The value of the record. Conflicts with 'data'."
  type        = string
  default     = null
}

variable "data" {
  description = "Map of attributes that constitute the record value. Conflicts with 'value'"
  type        = map(any)
  default     = {}
}

variable "timeouts" {
  description = "Timeout values for resources."
  type        = map(any)
  default     = {}
}