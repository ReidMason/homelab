#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Keep in sync with argocd/application.yaml → spec.sources[0].targetRevision
ARGOCD_CHART_VERSION="${ARGOCD_CHART_VERSION:-9.5.4}"

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update
helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version "${ARGOCD_CHART_VERSION}" \
  -f "${DIR}/argocd/values.yaml"

kubectl apply -n argocd -f "${DIR}/argocd/application.yaml"

CLUSTER_ENV="${CLUSTER_ENV:-dev}"
BOOTSTRAP_APP="${DIR}/argocd/bootstrap-${CLUSTER_ENV}.yaml"
if [[ ! -f "${BOOTSTRAP_APP}" ]]; then
  echo "No bootstrap Application for CLUSTER_ENV=${CLUSTER_ENV}: ${BOOTSTRAP_APP}" >&2
  exit 1
fi
kubectl apply -n argocd -f "${BOOTSTRAP_APP}"

if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
  echo "Initial admin password:"
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
  echo
else
  echo "No argocd-initial-admin-secret (already used or rotated)."
fi
