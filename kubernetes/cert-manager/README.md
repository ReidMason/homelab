# Set up cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm install --namespace=cert-manager cert-manager jetstack/cert-manager --version v1.15.3 --set crds.enabled=true --create-namespace -f values.yaml

# Create the issuers
kubectl apply -f issuers
```

You can now create certificates in any namespace
