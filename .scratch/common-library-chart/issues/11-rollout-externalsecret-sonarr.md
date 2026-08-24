# 11 — Roll out common.externalSecret to sonarr

**What to build:** `sonarr`'s `templates/externalsecret.yaml` (1 `data[]` entry for the exportarr metrics sidecar's API key, values nested under `.Values.homelab.metrics.externalSecret` rather than the flat `.Values.homelab.externalSecret` most other charts use) is replaced with a call to `common.externalSecret`. `sonarr` already depends on `common` for its toleration fragment — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/externalsecret.yaml` calls `common.externalSecret`, correctly sourcing from `.Values.homelab.metrics.externalSecret`
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
