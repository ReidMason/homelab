# 12 — Roll out common.externalSecret to tailscale-operator

**What to build:** `tailscale-operator`'s `templates/externalsecret.yaml` (2 `data[]` entries: client_id, client_secret, under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`. `Chart.yaml` declares `common` as a `file://../common` dependency.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `tailscale-operator/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
