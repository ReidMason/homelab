```bash
helm template external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true  > external-secrets-operator.yaml
```

# Setting up vault
```bash
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes_host:port/" \
  kubernetes_ca_cert=@ca.crt
```

```bash
vault write auth/kubernetes/role/kubernetes \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=read-secrets \
  ttl=1h
```
