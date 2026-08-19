# 03 — IngressRoute support

**What to build:** `service` renders a Traefik `IngressRoute` from `ingressRoute.*` values, reusing the shape already duplicated across ~20 charts today (`enabled`, `host`, `entryPoints[]`, `middleware.{enabled, name, namespace}`, `forwardAuth.{enabled, outpostServiceName, outpostServiceNamespace, outpostServicePort, middlewareName, middlewareNamespace}`). Output should match the existing per-chart `ingressroute.yaml` pattern (see e.g. `radarr`'s current template) byte-for-byte when given equivalent values, since this is meant to be a drop-in replacement for that duplicated logic as apps migrate later.

**Blocked by:** 1 — Scaffold `service` chart core

**Status:** ready-for-agent

- [ ] `ingressRoute.enabled: true` + `host` renders an `IngressRoute` with the configured entryPoints and host-matched route
- [ ] `ingressRoute.middleware.enabled: true` attaches the named/namespaced middleware
- [ ] `ingressRoute.forwardAuth.enabled: true` adds the forward-auth route (outpost service match) and middleware, matching the existing pattern's priority/ordering
- [ ] With `ingressRoute.enabled: false` (or unset), no `IngressRoute` renders
- [ ] Rendering test compares output against a fixture reproducing an existing chart's current `ingressRoute.*` values (e.g. `radarr`'s) and asserts equivalent output
