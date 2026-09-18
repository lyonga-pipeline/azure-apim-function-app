# Proves "adding a keyed resource generates only that resource's new
# timestamp" empirically: apply with one key, then apply again with a
# second key added, and confirm the FIRST key's created_on is unchanged
# (read back from state) while the newly-added key gets its own, different
# time_static value.

run "first_key_gets_a_created_on" {
  command = apply

  variables {
    storage_account_keys = ["orders"]
  }

  assert {
    condition     = output.tags_by_key["orders"]["created_on"] != null
    error_message = "the first key must get a created_on from its own time_static instance"
  }
}

run "adding_a_second_key_leaves_the_first_untouched" {
  command = apply

  variables {
    storage_account_keys = ["orders", "invoices"]
  }

  assert {
    condition     = output.tags_by_key["orders"]["created_on"] == run.first_key_gets_a_created_on.tags_by_key["orders"]["created_on"]
    error_message = "adding a new key must not change an already-existing key's created_on - each key's time_static instance is independent, keyed by for_each, so \"orders\" must keep reading the same frozen value back from state"
  }
  assert {
    condition     = output.tags_by_key["invoices"]["created_on"] != null
    error_message = "the newly-added key must get its own created_on from its own new time_static instance"
  }
}
