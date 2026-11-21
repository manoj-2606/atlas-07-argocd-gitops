#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Stage 3: Build, Scan & Push"
echo "=========================================="

ACR_NAME="$1"
ACR_LOGIN_SERVER="$2"
BUILD_ID="$3"
IMAGE_NAME="atlas-platform-app"
FULL_IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${BUILD_ID}"

# Multi-repo checkout paths (ADO creates subdirs per repo)
SELF_DIR="${BUILD_SOURCESDIRECTORY}/atlas-07-argocd-gitops"
APP_DIR="${BUILD_SOURCESDIRECTORY}/atlas-platform-app"

echo "Self repo: ${SELF_DIR}"
echo "App repo:  ${APP_DIR}"
echo "Image:     ${FULL_IMAGE}"

# Pre-download packages on host (host SSL is more stable than Docker's)
pip install pip --quiet --break-system-packages 2>/dev/null || true
pip download --dest "${APP_DIR}/vendor" \
  --timeout=300 --retries=5 \
  --trusted-host pypi.tuna.tsinghua.edu.cn \
  --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ \
  --python-version 312 --implementation cp --abi cp312 --only-binary=:all: --platform manylinux2014_x86_64 \
  -r "${APP_DIR}/requirements.txt"

# --- Docker Build (Dockerfile from P7 repo, context from app repo) ---
echo "[1/5] Docker Build..."
docker build -t "${FULL_IMAGE}" -f "${SELF_DIR}/Dockerfile" "${APP_DIR}"

# --- Trivy Install (apt repository method) ---
echo "[2/5] Install Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb \
  $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy

# --- Trivy Scan (zero CRITICAL policy) ---
echo "[3/5] Trivy Scan..."
trivy image --severity CRITICAL --exit-code 1 --no-progress "${FULL_IMAGE}"

# --- SBOM ---
echo "[4/5] SBOM Generation..."
trivy image --format spdx-json --output "${SELF_DIR}/sbom.json" "${FULL_IMAGE}"

# --- ACR Login + Push (SAME step — token expires between steps) ---
echo "[5/5] ACR Login + Push..."
az acr login --name "${ACR_NAME}"
docker push "${FULL_IMAGE}"

echo ""
echo "✅ Image pushed: ${FULL_IMAGE}"