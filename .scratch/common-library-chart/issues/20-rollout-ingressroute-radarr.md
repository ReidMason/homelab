# 20 — Roll out common.ingressRoute to radarr

**What to build:** `radarr`'s `templates/ingressroute.yaml` (full shape: `forwardAuth` outpost route + `middleware`, metadata name and target Service name both `radarr`) is replaced with a call to `common.ingressRoute`. `radarr` already depends on `common` — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` instead of hand-rendering the resource
- [x] `helm template` output is byte-identical to the pre-migration output for equivalent values, including the `forwardAuth`-enabled and `middleware`-enabled cases
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed
