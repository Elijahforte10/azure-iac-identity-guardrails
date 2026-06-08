# Azure IaC Identity Guardrails

Terraform that enforces a secure, identity-first baseline on Azure: custom
Azure Policies as code plus a secure-by-default storage resource that uses a
managed identity instead of access keys. Pair it with IaC scanning so insecure
definitions are caught before they deploy.

## What's here

| File | Purpose |
|---|---|
| `azure_policies.tf` | Custom Azure Policies (deny public blob access, require HTTPS) defined and assigned as code |
| `secure_storage.tf` | A storage account with managed identity, no keys, encryption, HTTPS-only, public access blocked |

## The identity-first idea

The storage account sets `shared_access_key_enabled = false` and uses a
**system-assigned managed identity**. That means no connection strings or
account keys live in code or config — access is granted via Entra ID RBAC
roles against the identity's principal ID (exported as an output). This is the
pattern that closes the most common cloud credential-leak path.

## Usage

```bash
terraform init
terraform plan  -var "scope_id=/subscriptions/<sub-id>" \
                -var "resource_group_name=rg-demo" \
                -var "storage_account_name=stsecuredemo01"
terraform apply

# Shift-left: scan before you ship (see the security-lab-toolkit repo)
tfsec .
checkov -d .
```

## Notes

- Conceptual reference — pin provider versions and adjust scope/region for your
  environment.
- `network_rules` defaults to **Deny**; add your VNet/IP exceptions explicitly.
- Grant data access with RBAC roles (e.g. *Storage Blob Data Reader*) against
  the managed identity rather than handing out keys.
