# 16 — Roll out common.ingressRoute to longhorn-system

**What to build:** `longhorn-system`'s `templates/ingressroute.yaml` (single route, no `forwardAuth`, no `middleware`, metadata name and target Service name both `longhorn-frontend`) is replaced with a call to `common.ingressRoute`. `Chart.yaml` declares `common` as a `file://../common` dependency (not currently present).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] `longhorn-system/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` instead of hand-rendering the resource
- [x] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed
