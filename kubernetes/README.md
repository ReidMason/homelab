# Kubernetes configs

This directory contains the configuration files for my kubernetes cluster.

# Initial setup

Start with argocd so that everything else can be deployed automatically.

```bash
# Inside the argocd directory
kubectl apply -k .

# Port forward the argocd server
kubectl port-forward service/argocd-server -n argocd 8080:443

# Pull the password for the argocd server
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

# Order of setup

Hopefully argocd should handle the rest but if this is being done from scratch the order of setup should be:

1. metallb
2. cert-manager
3. traefik
