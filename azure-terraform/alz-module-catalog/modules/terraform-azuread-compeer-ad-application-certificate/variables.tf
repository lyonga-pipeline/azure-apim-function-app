variable "application_object_id" {
  description = "The object ID of the application for which this certificate should be created."
  type        = string
}

variable "encoding" {
  description = "Specifies the encoding used for the supplied certificate data. Must be one of pem, base64 or hex."
  type        = string
  default     = "pem"
}

variable "end_date" {
  description = "The end date until which the certificate is valid, formatted as an RFC3339 date string."
  type        = string
  default     = null
}

variable "end_date_relative" {
  description = "A relative duration for which the certificate is valid until, for example 240h (10 days) or 2400h30m."
  type        = string
  default     = null
}

variable "key_id" {
  description = "A UUID used to uniquely identify this certificate."
  type        = string
  default     = null
}

variable "start_date" {
  description = "The start date from which the certificate is valid, formatted as an RFC3339 date string."
  type        = string
  default     = null
}

variable "type" {
  description = "The type of key/certificate. Must be one of AsymmetricX509Cert or Symmetric."
  type        = string
}

variable "value" {
  description = "The certificate data, which can be PEM encoded, base64 encoded DER or hexadecimal encoded DER."
  type        = string
}
