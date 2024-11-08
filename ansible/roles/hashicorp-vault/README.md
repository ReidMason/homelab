# Setting up vault

### Get the vault token

```bash
# On the host
docker logs hashicorp-vault
```

You should then see the root token in the logs. You can use this auth token to log in and set yourself up with a user.

### Set up the vault cli

```bash
EXPORT VAULT_ADDR=https://vault.skippythesnake.com/
vault login --method=userpass username=USERNAME
```

### Adding the kubernetes access method

This can also be done on the cli but using the web interface might be easier.

1. Go to the web interface and click on the `Access` tab.
2. Then click on the `Enable new auth method` button.
3. Select `Kubernetes` from the options.
4. Get the kubernetes host from the `.kube/config` file and use that as the host.
5. Get the CA certificate from the `.kube/config` file and use that as the cert. (you will need to base64 decode it)

### Create a role

Navigate to the `Roles` tab and click on the `Create role` button.
You can then set the name to whever you want.
For `Bound service account names` and `Bound service account namespaces` I use a wildcard `*` but you can be specific here if you want.

### Create a policy

Navigate to the `Policies` tab and click on the `Create policy` button.
You can then set the name to whever you want and then add the policy rules.
You probably want to keep it simple with basic read access.

```hcl
path "secrets/*"
{
  capabilities = ["read"]
}
```

### Assign the policy to the role

This part is strange. I think each entity is a client and you then assign policies to this client. So first you need to make the connection then assign the policy. I'm sure there's a way to automate this but I haven't found a way yet.

1. Navigate to the `Access` tab and click on the `Entities` section.
2. Locate your kubernetes role in the list and click on it.
3. Then click on the `Attach policy` button and select the policy you just created.
4. You can rename this policy to something more meaningful if you want.
5. Select `Edit entry`
6. Under `Policies` you can attach the policy you just created.
