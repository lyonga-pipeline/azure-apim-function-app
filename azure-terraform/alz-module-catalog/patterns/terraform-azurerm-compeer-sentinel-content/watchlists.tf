locals {
  watchlist_items = merge([
    for watchlist_key, watchlist in var.watchlists : {
      for item_key, row in watchlist.items : "${watchlist_key}/${item_key}" => {
        watchlist = watchlist_key
        row       = row
      }
    }
  ]...)
}

resource "azurerm_sentinel_watchlist" "watchlist" {
  for_each = var.watchlists

  name                       = each.key
  display_name               = each.value.display_name
  log_analytics_workspace_id = local.workspace_id
  description                = each.value.description
  item_search_key            = each.value.item_search_key
  default_duration           = each.value.default_duration
  labels                     = length(each.value.labels) == 0 ? null : each.value.labels
}

resource "azurerm_sentinel_watchlist_item" "item" {
  for_each = local.watchlist_items

  watchlist_id = azurerm_sentinel_watchlist.watchlist[each.value.watchlist].id
  properties   = each.value.row
}
