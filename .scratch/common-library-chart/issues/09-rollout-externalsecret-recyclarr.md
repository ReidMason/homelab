# 09 — Roll out common.externalSecret to recyclarr

**What to build:** `recyclarr`'s `templates/externalsecret.yaml` (1 `data[]` entry under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`. `recyclarr` already depends on `common` for its toleration fragment — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
