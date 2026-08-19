# 06 — Migrate `habit-tracker` onto `service`

**What to build:** `habit-tracker` runs on the shared `service` chart instead of the in-progress `bjw-s/common` dependency. Remove `bjw-s/common` entirely from `habit-tracker` (`Chart.lock`, `charts/`, `templates/common.yaml`, and the `dependencies:` block in `Chart.yaml`), and point `kubernetes-v2/values/prod/habit-tracker/deploy.yaml` at `chart: service`, with `kubernetes-v2/values/prod/habit-tracker/values.yaml` supplying `habit-tracker`'s image, NFS storage config (server/path from `fern.internal`), and ingressRoute config against `service`'s schema. The app's own `kubernetes-v2/charts/habit-tracker/` chart directory is removed (or left empty/deleted) since it's now backed by `service`.

**Blocked by:** 2 (storage support), 3 (ingressRoute support) — habit-tracker needs both, doesn't need probes/secretEnv/metricsSidecar

**Status:** ready-for-agent

- [ ] `bjw-s/common` is fully removed from `habit-tracker` — no `Chart.lock`, `charts/`, `common.yaml`, or `dependencies:` remain
- [ ] `deploy.yaml` for `habit-tracker` sets `chart: service`
- [ ] `values/prod/habit-tracker/values.yaml` (plus the chart-level defaults if applicable) reproduces current behavior: same image, NFS-backed storage against `fern.internal`, same ingressRoute config
- [ ] `helm template` output for `habit-tracker` renders a Deployment, Service, PV+PVC, and (if `ingressRoute.enabled`) IngressRoute equivalent to its current behavior
- [ ] Manual read-only review (`kubectl diff`-style, no applying) confirms no unexpected resource changes before considering this done
