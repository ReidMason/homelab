# Setting up vault

### Get the vault token

```bash
# On the host
docker logs hashicorp-vault
```

You should then see the root token in the logs

### Auth to vault

```bash
EXPORT VAULT_ADDR=https://vault.skippythesnake.com/
vault login
```

### Enable the kubernetes auth method

```bash
vault auth enable kubernetes
```

### Ideal world

So ideally we want to use the kubernetes service account to authenticate with vault but this is broken so instead we just ended up using the token as a secret then use token authentication

```bash
kubectl create secret generic vault-token --from-literal=token=<TOKEN>
```

I think you need to get the CA cert from the kubernetes cluster by copying it from the `.kube/config` file, then base 64 decode it and use that. But even by doing this I still can't get it to authenticate with kubernetes.

### Configure the kubernetes auth method

```bash
vault write auth/kubernetes/role/kubernetes-dev \
    bound_service_account_names=external-secrets-service-account \
    bound_service_account_namespaces=external-secrets \
    policies=external-secrets-policy \
    ttl=24h
```

### Create a policy

```bash
vault policy write kubernetes-dev-policy - <<EOF
path "secret/kubernetes-dev/*" {
  capabilities = ["read"]
}
EOF
```
