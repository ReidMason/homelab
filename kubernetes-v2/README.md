# kubernetes-v2

## Argo CD

Install / upgrade Argo CD and apply the self-managed `Application` (run from anywhere):

```bash
./kubernetes-v2/bootstrap.sh
```

**UI:** open `https://localhost:8080` after:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

**Initial admin password:** printed at the end of `bootstrap.sh` when `argocd-initial-admin-secret` still exists (first install).

## Vault AppRole secret (SealedSecret)

Used for `vault-approle-eso` in the `external-secrets` namespace. Plain `kubectl create secret` is only a one-off.

1. **Find the controller Service**:

   ```bash
   kubectl get svc -n sealed-secrets
   ```

2. **Seal the secret** (replace `NAME` with the Service name from step 2, and the literals with your role ID and secret ID):

   ```bash
   kubectl create secret generic vault-approle-eso -n external-secrets \
     --from-literal=role-id='YOUR_ROLE_ID' \
     --from-literal=secret-id='YOUR_SECRET_ID' \
     --dry-run=client -o yaml \
   | kubeseal --format yaml \
       --controller-namespace sealed-secrets \
       --controller-name NAME \
       -o yaml
   ```

3. **Put only `spec.encryptedData` in git** under `kubernetes-v2/values/dev/external-secrets/values.yaml`:
   - `homelab.vaultAppRoleSealedSecret.enabled: true`
   - `homelab.vaultAppRoleSealedSecret.encryptedData.role-id` and `.secret-id` — copy the two ciphertext lines from the `kubeseal` output.
