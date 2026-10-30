locals {
  archive = var.archive == null ? {} : { primary = var.archive }
}
