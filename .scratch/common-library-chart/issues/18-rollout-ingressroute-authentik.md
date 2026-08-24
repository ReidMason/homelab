# 18 — Roll out common.ingressRoute to authentik

**What to build:** `authentik`'s `templates/ingressroute.yaml` (single route, no `forwardAuth`, no `middleware` — authentik is the identity provider itself, so it has no upstream forwardAuth guard — metadata name and target Service name both `authentik`) is replaced with a call to `common.ingressRoute`. `authentik` already depends on `common` (used for `common.toleration`/`common.externalSecret`) — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` instead of hand-rendering the resource
- [x] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed
