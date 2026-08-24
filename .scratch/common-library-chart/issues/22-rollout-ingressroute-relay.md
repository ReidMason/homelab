# 22 — Roll out common.ingressRoute to relay (ingest)

**What to build:** `relay`'s `templates/ingest-ingressroute.yaml` (single route, no `forwardAuth`, no `middleware`, metadata name and target Service name both `relay-ingest`, values nested under `.Values.ingest.homelab.ingressRoute` rather than the flat `.Values.homelab.ingressRoute` most other charts use — same nesting pattern already handled for `relay`'s `externalSecret` in ticket 10) is replaced with a call to `common.ingressRoute`, passing the nested values block through to the fragment's dict signature. `relay` already depends on `common` — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] `templates/ingest-ingressroute.yaml` calls `common.ingressRoute`, correctly sourcing from `.Values.ingest.homelab.ingressRoute`
- [x] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed
