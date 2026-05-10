# kubernetes-v2

## Argo CD

Install / upgrade Argo CD and apply the self-managed `Application` (run from anywhere):

```bash
./kubernetes-v2/bootstrap.sh
```

**UI:** open `https://localhost:8080` after:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

**Initial admin password:** printed at the end of `bootstrap.sh` when `argocd-initial-admin-secret` still exists (first install).
