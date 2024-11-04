# Update template files

```bash
# Add the traefik helm repo
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create the traefik.yaml file
helm template traefik traefik/traefik --include-crds -f values.yaml > traefik.yaml
```
