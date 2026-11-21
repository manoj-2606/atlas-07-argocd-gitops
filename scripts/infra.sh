#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Stage 2: Infrastructure Provisioning"
echo "=========================================="

# --- OIDC Auth for Terraform (AzureCLI@2 sets these with addSpnToEnvironment) ---
export ARM_USE_OIDC=true
export ARM_CLIENT_ID=$servicePrincipalId
export ARM_TENANT_ID=$tenantId
export ARM_OIDC_TOKEN=$idToken
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "[1/4] Terraform Init..."
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-atlas-tfstate" \
  -backend-config="storage_account_name=atlastfstate2606" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=atlas-07.tfstate" \
  -backend-config="use_oidc=true"

echo "[2/4] Terraform Plan..."
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

echo "[3/4] Terraform Apply..."
terraform apply -auto-approve tfplan

echo "[4/4] Saving Outputs..."
RG_NAME=$(terraform output -raw resource_group_name)
ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
AKS_NAME=$(terraform output -raw aks_cluster_name)
cd ..

# Set output variables for downstream stages
echo "##vso[task.setvariable variable=RG_NAME;isOutput=true]$RG_NAME"
echo "##vso[task.setvariable variable=ACR_NAME;isOutput=true]$ACR_NAME"
echo "##vso[task.setvariable variable=ACR_LOGIN_SERVER;isOutput=true]$ACR_LOGIN_SERVER"
echo "##vso[task.setvariable variable=AKS_NAME;isOutput=true]$AKS_NAME"

echo ""
echo "✅ Infrastructure provisioned"
echo "   RG:  $RG_NAME"
echo "   ACR: $ACR_LOGIN_SERVER"
echo "   AKS: $AKS_NAME"