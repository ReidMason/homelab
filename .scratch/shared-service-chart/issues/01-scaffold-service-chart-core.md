# 01 — Scaffold `service` chart core

**What to build:** `kubernetes-v2/charts/service` exists as a real, standalone, renderable Helm chart — no third-party or local `dependencies:`, no `Chart.lock`, no vendoring — implementing the core of the shape described in `.scratch/shared-service-chart/spec.md` and `docs/adr/0006-hand-rolled-service-chart-over-bjws-common.md`: a single-container Deployment plus a Service, driven by a flat values schema (`image.repository`, `image.tag`, `containerPort`, `service.port`), with the standard `node.kubernetes.io/unreachable`/`NoExecute`/10s toleration applied by default. Resource names are derived from `.Release.Name` (not hardcoded), since this chart will back multiple releases.

This ticket also establishes the rendering-test tooling this repo doesn't yet have: pick a lightweight `helm template`-based approach (snapshot comparison script, or the `helm unittest` plugin) and set it up so later tickets can add fixture-based tests against it.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `kubernetes-v2/charts/service/Chart.yaml` exists with no `dependencies:` block
- [ ] Deployment renders with image, containerPort, and the default `unreachable` toleration from values
- [ ] Service renders with the configured port, targeting the Deployment's containerPort
- [ ] Resource names (Deployment, Service) are derived from `.Release.Name`, not a hardcoded app name
- [ ] A rendering-test approach is chosen and working (e.g. `helm template` + snapshot script, or `helm unittest`), documented for later tickets to extend
- [ ] At least one minimal fixture test exists (image + containerPort only, no other blocks) and passes
