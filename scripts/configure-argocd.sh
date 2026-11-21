#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Stage 5: Configure ArgoCD Applications"
echo "=========================================="

ACR_LOGIN_SERVER="$1"
BUILD_ID="$2"
AKS_NAME="$3"
RG_NAME="$4"

echo "ACR: ${ACR_LOGIN_SERVER}"
echo "Image Tag: ${BUILD_ID}"

# --- Get AKS credentials ---
az aks get-credentials \
  --resource-group "$RG_NAME" \
  --name "$AKS_NAME" \
  --overwrite-existing

# --- Apply AppProject (RBAC boundary) ---
echo "[1/3] Applying AppProject..."
kubectl apply -f argocd/appprojects/atlas-project.yaml
echo "  AppProject 'atlas-project' applied"

# --- Apply Application CRD (replace placeholders with runtime values) ---
echo "[2/3] Applying Application CRD..."
sed -e "s|ACR_LOGIN_SERVER_PLACEHOLDER|${ACR_LOGIN_SERVER}|g" \
    -e "s|value: \"latest\"|value: \"${BUILD_ID}\"|g" \
    argocd/applications/atlas-platform-dev.yaml | kubectl apply -f -
echo "  Application 'atlas-platform-dev' applied"
echo "  → image: ${ACR_LOGIN_SERVER}/atlas-platform-app:${BUILD_ID}"

# --- Wait for ArgoCD to sync ---
echo "[3/3] Waiting for ArgoCD sync..."
echo "  ArgoCD is now pulling from Git and deploying to dev namespace..."
echo "  This is the GitOps moment — pipeline is NOT deploying the app."
echo ""

MAX_RETRIES=20
RETRY_INTERVAL=15

for i in $(seq 1 $MAX_RETRIES); do
  SYNC_STATUS=$(kubectl get application atlas-platform-dev -n argocd \
    -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
  HEALTH_STATUS=$(kubectl get application atlas-platform-dev -n argocd \
    -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

  echo "  [$i/$MAX_RETRIES] Sync=${SYNC_STATUS}  Health=${HEALTH_STATUS}"

  if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
    echo ""
    echo "✅ ArgoCD Application synced and healthy!"
    echo ""
    echo "=== ArgoCD Application ==="
    kubectl get application -n argocd
    echo ""
    echo "=== App Pods (deployed by ArgoCD, NOT by pipeline) ==="
    kubectl get pods -n dev
    exit 0
  fi

  sleep $RETRY_INTERVAL
done

echo ""
echo "⚠️ ArgoCD sync did not complete in expected time"
echo "  This may be normal — ArgoCD might still be pulling the image."
echo "  Check manually:"
echo "    kubectl get application -n argocd"
echo "    kubectl describe application atlas-platform-dev -n argocd"
echo ""
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20
exit 1