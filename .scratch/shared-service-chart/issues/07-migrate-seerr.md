# 07 — Migrate `seerr` onto `service`

**What to build:** `seerr` runs on the shared `service` chart instead of the in-progress `bjw-s/common` dependency. Remove `bjw-s/common` entirely from `seerr` (`Chart.lock`, `charts/`, `templates/common.yaml`, and the `dependencies:` block in `Chart.yaml`), and point `kubernetes-v2/values/prod/seerr/deploy.yaml` at `chart: service`, with `kubernetes-v2/values/prod/seerr/values.yaml` supplying `seerr`'s image, NFS storage config, ingressRoute config, and probe config (`/api/v1/settings/public`) against `service`'s schema. The app's own `kubernetes-v2/charts/seerr/` chart directory is removed since it's now backed by `service`.

This ticket also resolves the open question from the spec: `seerr`'s old chart set `securityContext.fsGroup: 1000` (`fsGroupChangePolicy: OnRootMismatch`) at the pod level, which `service`'s current schema (tickets 01-05) doesn't cover. Confirm during implementation whether `seerr` actually needs this (check whether the mounted NFS volume's permissions require it) — if yes, decide whether to fold a `storage.fsGroup`-style field into `service`'s schema (may require reopening ticket 02) or handle it another way; if no, drop it and note why in this ticket's notes.

**Blocked by:** 2 (storage support), 3 (ingressRoute support), 4 (probes support)

**Status:** ready-for-agent

- [ ] `bjw-s/common` is fully removed from `seerr` — no `Chart.lock`, `charts/`, `common.yaml`, or `dependencies:` remain
- [ ] `deploy.yaml` for `seerr` sets `chart: service`
- [ ] `values/prod/seerr/values.yaml` reproduces current behavior: same image, NFS-backed storage, same ingressRoute config, readiness/liveness probes against `/api/v1/settings/public`
- [ ] The `fsGroup` question is explicitly resolved (schema change or documented as unnecessary), not silently dropped
- [ ] `helm template` output for `seerr` renders a Deployment, Service, PV+PVC, IngressRoute, and probes equivalent to its current behavior
- [ ] Manual read-only review (`kubectl diff`-style, no applying) confirms no unexpected resource changes before considering this done

**Notes:**

`fsGroup` resolution: `seerr` runs as a non-root user and writes to `/app/config`, which is backed by an NFS-mounted PVC — several other charts in this repo (`postgres`, `pihole`, `radarr`, `qbittorrent`, `sonarr`) apply the same pod-level `fsGroup`/`fsGroupChangePolicy: OnRootMismatch` pattern for the same reason (NFS exports don't otherwise grant the container's UID write access). This isn't a one-off, so `service`'s schema was extended with an optional `storage.fsGroup` field (ticket 02 reopened): when set, the Deployment template adds `securityContext.fsGroup`/`fsGroupChangePolicy: OnRootMismatch` at the pod level; when unset (the default, `""`), no `securityContext` block is rendered, matching every other migrated chart's untouched behavior. `seerr`'s values set `storage.fsGroup: 1000` to reproduce its old chart's behavior exactly. Covered by a new `tests/fixtures/storage-fsgroup.yaml` fixture on the `service` chart.
