# kubernetes-v2

Helm values and small manifests. Pin chart versions on the CLI and in `application.yaml` where noted.

## MetalLB

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm upgrade --install metallb metallb/metallb \
  -n metallb-system --create-namespace \
  --version 0.15.3 \
  -f metallb/values.yaml
kubectl apply -f metallb/pool.yaml
```

## Argo CD (same values for bootstrap and GitOps)

Install / upgrade Argo CD and apply the self-managed `Application` (run from anywhere):

```bash
./kubernetes-v2/bootstrap.sh
```

**UI:** open `https://localhost:8080` after:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

**Initial admin password:** printed at the end of `bootstrap.sh` when `argocd-initial-admin-secret` still exists (first install). Otherwise:
