locals {
  types_using_value = ["A", "AAAA", "CNAME", "TXT", "SPF", "PTR"]
  types_using_data  = ["MX", "SRV", "LOC", "CAA", "CERT", "DNSKEY", "DS", "NAPTR", "SMIMEA", "SSHFP", "TLSA", "URI", "HTTPS", "SVCB"]

  require_value = contains(local.types_using_value, var.type)
  require_data  = contains(local.types_using_data, var.type)
}