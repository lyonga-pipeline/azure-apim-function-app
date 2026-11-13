variable "records" {
  description = "DNS records with resolved zone IDs and content. The caller owns tunnel defaults and publication ordering."
  type = map(object({
    zone_id         = string
    name            = string
    type            = string
    content         = string
    ttl             = optional(number, 1)
    proxied         = optional(bool, true)
    comment         = optional(string)
    priority        = optional(number)
    allow_overwrite = optional(bool, false)
    tags            = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([for record in values(var.records) : upper(record.type) != "CNAME" || length([
      for other in values(var.records) : other
      if lower(other.zone_id) == lower(record.zone_id) && lower(trimsuffix(other.name, ".")) == lower(trimsuffix(record.name, "."))
    ]) == 1])
    error_message = "A CNAME zone/hostname cannot have another declared record. Use fully qualified names; legitimate multi-value non-CNAME records remain supported."
  }
}
