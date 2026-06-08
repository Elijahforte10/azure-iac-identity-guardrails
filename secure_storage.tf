# secure_storage.tf — a secure-by-default storage account using managed identity
#
# Demonstrates the identity-first pattern: no access keys / connection strings
# in code, a system-assigned managed identity for the resource, encryption,
# HTTPS-only, and public access blocked. This is the "known good" resource your
# tfsec/checkov pipeline should pass clean.

variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "storage_account_name" {
  type        = string
  description = "3-24 lowercase alphanumeric chars, globally unique"
}

resource "azurerm_storage_account" "secure" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 7 }
  }

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = {
    ManagedBy = "Terraform"
    Baseline  = "secure-identity-first"
  }
}

output "storage_identity_principal_id" {
  description = "Use this principal ID to grant RBAC data roles instead of keys"
  value       = azurerm_storage_account.secure.identity[0].principal_id
}
