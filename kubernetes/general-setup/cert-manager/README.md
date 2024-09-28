# Setting up cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.3 \
  --set crds.enabled=true
```

# Issuer

The issuer hands out the SSL certs. This is unique to each namespace. A cluster issuer is global across the whole cluster
