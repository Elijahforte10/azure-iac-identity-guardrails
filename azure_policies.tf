# azure_policies.tf — Azure Policy as code (identity & data guardrails)
#
# Defines and assigns custom Azure Policies that enforce a secure baseline at
# the platform level. Policy-as-code means these guardrails are versioned,
# reviewed, and applied consistently across subscriptions — drift can't quietly
# reintroduce an insecure default.
#
# Conceptual reference — set provider/scope for your environment.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "scope_id" {
  type        = string
  description = "Management group or subscription ID to assign policies at"
}

# --- Policy 1: deny storage accounts that allow public blob access ----------
resource "azurerm_policy_definition" "deny_public_storage" {
  name         = "deny-public-blob-access"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny storage accounts with public blob access"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess", equals = "true" }
      ]
    }
    then = { effect = "deny" }
  })
}

# --- Policy 2: require HTTPS-only on storage accounts ------------------------
resource "azurerm_policy_definition" "require_https_storage" {
  name         = "require-https-storage"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require secure transfer (HTTPS) on storage accounts"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly", notEquals = "true" }
      ]
    }
    then = { effect = "deny" }
  })
}

# --- Assignments ------------------------------------------------------------
resource "azurerm_policy_assignment" "deny_public_storage" {
  name                 = "deny-public-blob-access"
  scope                = var.scope_id
  policy_definition_id = azurerm_policy_definition.deny_public_storage.id
  display_name         = "Deny public blob access"
}

resource "azurerm_policy_assignment" "require_https_storage" {
  name                 = "require-https-storage"
  scope                = var.scope_id
  policy_definition_id = azurerm_policy_definition.require_https_storage.id
  display_name         = "Require HTTPS on storage"
}
