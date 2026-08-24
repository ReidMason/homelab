# 25 — Roll out common.ingressRoute to portainer

**What to build:** `portainer`'s `templates/ingressroute.yaml` is replaced with a call to `common.ingressRoute`. `portainer` already depends on `common` (used for `common.toleration` — ticket 02's rollout).

This is **not a mechanical swap** — the current template sets an explicit `scheme: {{ .Values.homelab.ingressRoute.scheme }}` on the routed Service (Portainer's webui needs `scheme: https` since it terminates its own TLS), a field `common.ingressRoute` doesn't currently expose. It also targets a differently-named Service (`portainer-webui`) than its own `metadata.name` (`portainer`) — same class of pre-existing name/target split as tickets 14/23/24, though here it's paired with the missing `scheme` field.

**Blocked by:** None — can start immediately, but requires a decision before implementing (see below), not just a mechanical swap.

**Status:** ready-for-agent

- [x] Explicit decision made and recorded: does `common.ingressRoute` need an optional `scheme` param on the primary route's service entry (only emitted when set, to stay byte-identical for every other caller that doesn't use it)?
- [x] Explicit decision made and recorded: same `metadata.name`/target-Service-name split question as tickets 23/24 — resolve consistently with whatever those tickets decide
- [x] `templates/ingressroute.yaml` calls `common.ingressRoute` (or documents why it can't, if either decision above rules it out)
- [x] `helm template` output reviewed and diffed against pre-migration output; any differences are the ones explicitly decided above, nothing incidental
- [x] No vendored `charts/*.tgz`/`Chart.lock` committed

**Notes:**

Flagged during survey: portainer's `forwardAuth`-guarded route only adds middlewares in the `forwardAuth.enabled` branch (missing the `middleware.enabled` OR-condition every other full-shape chart has) — confirm whether that's intentional (portainer has no `middleware.enabled` config today) or a latent gap before assuming `common.ingressRoute`'s `or middleware.enabled forwardAuth.enabled` guard is a safe drop-in.

**Decision (recorded during implementation):** `common.ingressRoute` now takes two additional optional inputs, both no-ops for existing callers: `serviceName` (defaults to `name` when unset — resolves the metadata-name/target-Service-name split for tickets 23/24/25) and `ingressRoute.scheme` (only emitted on the primary route's Service entry when set). Portainer's `values.yaml` gained an explicit `middleware: {enabled: false, name: "", namespace: ""}` block so the fragment's `or middleware.enabled forwardAuth.enabled` guard is a safe drop-in — confirmed this reproduces byte-identical output to the hand-rolled forwardAuth-only guard since portainer never had a real `middleware.enabled` config.
