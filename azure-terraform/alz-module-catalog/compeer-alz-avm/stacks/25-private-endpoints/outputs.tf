output "private_endpoint_ids" { value = { for k, v in module.private_endpoint : k => v.id } }
