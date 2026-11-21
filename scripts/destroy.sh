#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Destroy: Terraform Destroy"
echo "=========================================="

# --- OIDC Auth ---
export ARM_USE_OIDC=true
export ARM_CLIENT_ID=$servicePrincipalId
export ARM_TENANT_ID=$tenantId
export ARM_OIDC_TOKEN=$idToken
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "[1/3] Terraform Init..."
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-atlas-tfstate" \
  -backend-config="storage_account_name=atlastfstate2606" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=atlas-07.tfstate" \
  -backend-config="use_oidc=true"

echo "[2/3] Terraform Destroy..."
terraform destroy -var-file="environments/dev.tfvars" -auto-approve
cd ..

echo "[3/3] Verifying deletion..."
RG_EXISTS=$(az group exists --name "rg-atlas-07-dev")
if [[ "$RG_EXISTS" == "false" ]]; then
  echo "✅ Resource group rg-atlas-07-dev deleted"
else
  echo "⚠️ Resource group still exists — check Azure Portal"
  exit 1
fi