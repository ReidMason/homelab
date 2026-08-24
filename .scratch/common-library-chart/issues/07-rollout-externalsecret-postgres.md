# 07 — Roll out common.externalSecret to postgres

**What to build:** `postgres`'s `templates/externalsecret.yaml` (2 `data[]` entries: admin-username, admin-password, under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`. `postgres` already depends on `common` for its toleration fragment — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
