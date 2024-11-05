## Setup argocd

```bash
kubectl apply -k .

# Port forward the argocd server
kubectl port-forward service/argocd-server -n argocd 8080:443
```

You should then be able to access the argocd server at https://localhost:8080

## Adding applications

Example applications can be found in the `applications` directory.\
To add an application use these for reference. You'll need to create another yaml file and add it to the `kustomization.yaml` file.
