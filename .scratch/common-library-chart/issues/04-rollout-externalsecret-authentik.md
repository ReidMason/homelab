# 04 — Roll out common.externalSecret to authentik

**What to build:** `authentik`'s `templates/externalsecret.yaml` (4 `data[]` entries: secret-key, db-password, bootstrap-password, bootstrap-email, all sourced from one remote Vault key under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`, matching the fragment's dict signature (`name`, `remoteKey`, `refreshInterval`, `clusterSecretStoreName`, `secretEnv` list of `{secretKey, property}`, `enabled`). `authentik/Chart.yaml` declares `common` as a `file://../common` dependency (version-pinned to `common`'s current version).

**Blocked by:** None — can start immediately (`common.externalSecret` already exists and is verified).

**Status:** ready-for-agent

- [ ] `authentik/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values (all 4 data entries, same secretKey/property pairs)
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
