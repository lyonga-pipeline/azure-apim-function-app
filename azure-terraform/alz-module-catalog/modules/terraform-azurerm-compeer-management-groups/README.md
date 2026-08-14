# Compeer Management Groups

Creates the ALZ management group hierarchy and optional subscription placement associations.

This module is intended for subscription vending and platform governance roots. It uses a keyed map so future management groups can be added without changing the module interface. Publish this to HCP before go-live if management group creation is owned by Terraform.
