resource "azurerm_container_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  ip_address_type     = var.ip_address_type
  dns_name_label      = var.dns_name_label
  subnet_ids          = var.subnet_ids
  restart_policy      = var.restart_policy
  zones               = var.zones
  tags                = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "image_registry_credential" {
    for_each = var.image_registry_credentials
    content {
      server   = image_registry_credential.value.server
      username = try(image_registry_credential.value.username, null)
      password = try(image_registry_credential.value.password, null)
    }
  }

  dynamic "container" {
    for_each = var.containers
    content {
      name   = container.key
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      commands                     = try(container.value.commands, null)
      environment_variables        = try(container.value.environment_variables, null)
      secure_environment_variables = try(container.value.secure_environment_variables, null)

      dynamic "ports" {
        for_each = try(container.value.ports, [])
        content {
          port     = ports.value.port
          protocol = try(ports.value.protocol, "TCP")
        }
      }

      dynamic "volume" {
        for_each = try(container.value.volumes, {})
        content {
          name                 = volume.key
          mount_path           = volume.value.mount_path
          read_only            = try(volume.value.read_only, false)
          share_name           = try(volume.value.share_name, null)
          storage_account_name = try(volume.value.storage_account_name, null)
          storage_account_key  = try(volume.value.storage_account_key, null)
          empty_dir            = try(volume.value.empty_dir, null)
          secret               = try(volume.value.secret, null)

          dynamic "git_repo" {
            for_each = try(volume.value.git_repo, null) == null ? [] : [volume.value.git_repo]
            content {
              url       = git_repo.value.url
              directory = try(git_repo.value.directory, null)
              revision  = try(git_repo.value.revision, null)
            }
          }
        }
      }
    }
  }

  dynamic "exposed_port" {
    for_each = var.exposed_ports
    content {
      port     = exposed_port.value.port
      protocol = try(exposed_port.value.protocol, "TCP")
    }
  }
}
