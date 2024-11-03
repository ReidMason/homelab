# Refresh the cert-manager yaml

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm template --namespace=cert-manager cert-manager jetstack/cert-manager --version v1.15.3 --set crds.enabled=true --create-namespace -f values.yaml > cert-manager.yaml
```
