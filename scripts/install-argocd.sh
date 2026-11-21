#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Stage 4: Install ArgoCD"
echo "=========================================="

CHART_VERSION="$1"
AKS_NAME="$2"
RG_NAME="$3"

echo "ArgoCD Chart Version: ${CHART_VERSION}"
echo "AKS: ${AKS_NAME} in ${RG_NAME}"

# --- Get AKS credentials ---
echo "[1/4] Getting AKS credentials..."
az aks get-credentials \
  --resource-group "$RG_NAME" \
  --name "$AKS_NAME" \
  --overwrite-existing

# --- Create namespace ---
echo "[2/4] Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# --- Helm install (clean install — uninstall first if stuck) ---
echo "[3/4] Installing ArgoCD via Helm..."
helm uninstall argocd -n argocd 2>/dev/null || true

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --version "$CHART_VERSION" \
  --values argocd/install/values-argocd.yaml \
  --wait --timeout 300s

# --- Wait for all ArgoCD components ---
echo "[4/4] Waiting for ArgoCD pods..."
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s

kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-repo-server \
  -n argocd --timeout=120s

kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-application-controller \
  -n argocd --timeout=120s

echo ""
echo "✅ ArgoCD installed and all pods Ready"
kubectl get pods -n argocd