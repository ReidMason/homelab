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

if [[ -n "${CLUSTER_ENV:-}" && -f "${DIR}/argocd/applicationset-${CLUSTER_ENV}.yaml" ]]; then
  kubectl apply -n argocd -f "${DIR}/argocd/applicationset-${CLUSTER_ENV}.yaml"
fi

if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
  echo "Initial admin password:"
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
  echo
else
  echo "No argocd-initial-admin-secret (already used or rotated)."
fi
