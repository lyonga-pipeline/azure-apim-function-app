locals {
  security_rules_from_list = {
    for rule in var.security_rule : rule.name => rule
  }

  security_rules = merge(local.security_rules_from_list, var.security_rules)
}
