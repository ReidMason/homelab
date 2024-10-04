# Setup

```bash
# Add the traefik helm repo
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create the namespace
kubectl create namespace traefik

helm install --namespace=traefik --create-namespace traefik traefik/traefik -f values.yaml
```

To update the config

```bash
helm upgrade --namespace=traefik traefik traefik/traefik -f values.yaml
```

Setup the dashboard

```bash
kubectl apply -f dashboard
```

```bash
kubectl apply -f certificates/dev.yaml

# Check the status
kubectl get certificates

# Check the status of the request
kubectl get certificaterequests
```
