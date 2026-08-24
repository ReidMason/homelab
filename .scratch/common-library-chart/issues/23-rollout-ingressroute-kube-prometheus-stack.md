# 23 — Roll out common.ingressRoute to kube-prometheus-stack

**What to build:** `kube-prometheus-stack`'s `templates/ingressroute.yaml` is replaced with a call to `common.ingressRoute`. `Chart.yaml` already depends on `common` (used for its `externalSecret` fragments — tickets 05).

This is **not a mechanical swap** — the current template's `metadata.name` (`grafana`) and the target Service name (`{{ .Release.Name }}-grafana`) already differ today, the same shape of pre-existing name/target mismatch found in ticket 14 (cert-manager). `common.ingressRoute` uses a single `name` input for both `metadata.name` and the route's target Service name, so it can't reproduce this split as-is.

**Blocked by:** None — can start immediately, but requires a decision before implementing (see below), not just a mechanical swap.

**Status:** ready-for-agent

- [x] Explicit decision made and recorded: does `common.ingressRoute` need a second parameter (e.g. `serviceName`, defaulting to `name` when unset) to let `metadata.name` and the routed Service name differ, or is renaming the `IngressRoute` object (or pointing it at a differently-named Service) acceptable here?
- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` (or documents why it can't, if the decision above rules it out)
- [x] `helm template` output reviewed and diffed against pre-migration output; any differences are the ones explicitly decided above, nothing incidental
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed

**Notes:**

Flagged during survey: unlike most rollout tickets in this batch, this one surfaces a real pre-existing metadata-name/target-name split rather than just relocating working code.

**Decision (recorded during implementation):** added an optional `serviceName` input to `common.ingressRoute`, defaulting to `name` when unset (no-op for every other caller). Called with `serviceName: "{{ .Release.Name }}-grafana"` to reproduce the existing split; verified `helm template` output is byte-identical to pre-migration.
