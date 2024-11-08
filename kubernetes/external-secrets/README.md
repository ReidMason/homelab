```bash
helm template external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true  > external-secrets-operator.yaml
```
