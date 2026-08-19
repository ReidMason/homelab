# 05 — metricsSidecar support

**What to build:** `service` supports one optional dedicated second container, `metricsSidecar.{enabled, image.repository, image.tag, port, args[], apiKeySecret.name, apiKeySecret.key}`, matching the existing `sonarr`/`exportarr` pattern exactly (a metrics exporter hitting the main container over `localhost`, one port, one API-key env var sourced from a secret). This is a single dedicated slot, not a generic multi-container mechanism — see ADR-0006 for why generic `containers: []` support was rejected.

**Blocked by:** 4 — Probes + secretEnv support (also edits the Deployment's container list; sequenced to avoid rework/merge conflicts)

**Status:** ready-for-agent

- [ ] `metricsSidecar.enabled: true` renders exactly one additional container in the Deployment's pod spec, alongside the main container
- [ ] The sidecar container gets its own image, port, args, and an API-key env var sourced via `secretKeyRef` from `metricsSidecar.apiKeySecret.{name,key}`
- [ ] The sidecar's config (image, env, port) does not leak onto or overwrite the main container's spec
- [ ] `metricsSidecar.enabled: false` (default) renders only the main container
- [ ] Rendering tests cover: sidecar enabled (asserting both containers present and correctly configured) and disabled
