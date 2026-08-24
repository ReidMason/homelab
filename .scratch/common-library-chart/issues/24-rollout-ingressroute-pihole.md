# 24 — Roll out common.ingressRoute to pihole

**What to build:** `pihole`'s `templates/ingressroute.yaml` is replaced with a call to `common.ingressRoute`. `pihole` already depends on `common` (used for `common.toleration`/`common.externalSecret` — ticket 06).

This is **not a mechanical swap** — the current template's `metadata.name` (`pihole`) and the target Service name (`pihole-dashboard`) already differ today, the same shape of pre-existing name/target mismatch found in ticket 14 (cert-manager) and ticket 23 (kube-prometheus-stack). `common.ingressRoute` uses a single `name` input for both `metadata.name` and the route's target Service name, so it can't reproduce this split as-is.

**Blocked by:** None — can start immediately, but requires a decision before implementing (see below), not just a mechanical swap.

**Status:** ready-for-agent

- [x] Explicit decision made and recorded: does `common.ingressRoute` need a second parameter (e.g. `serviceName`, defaulting to `name` when unset) to let `metadata.name` and the routed Service name differ, or is renaming the `IngressRoute` object (or pointing it at a differently-named Service) acceptable here?
- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` (or documents why it can't, if the decision above rules it out)
- [x] `helm template` output reviewed and diffed against pre-migration output; any differences are the ones explicitly decided above, nothing incidental
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed

**Notes:**

Flagged during survey: same class of issue as ticket 23 — if a `serviceName` param gets added to `common.ingressRoute` to resolve one of these, resolve both tickets with the same fragment change rather than picking a different approach per chart.

**Decision (recorded during implementation):** used the same `serviceName` input added for ticket 23, called with `serviceName: "pihole-dashboard"`; verified `helm template` output is byte-identical to pre-migration.
