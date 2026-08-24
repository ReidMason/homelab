# Context

## Alerting

Prometheus `PrometheusRule` resources per app, routed through a single Alertmanager (`kubernetes-v2/charts/kube-prometheus-stack`) to Discord. See `docs/adr/0001-prometheus-alerting-conventions.md` for the label schema, severity tiers, and routing conventions new alert rules should follow.

## Logging

Loki (log store, `kubernetes-v2/charts/loki`) + Alloy (log shipper, `kubernetes-v2/charts/alloy`), queried from Grafana. Started as a syslog receiver for fern.internal (Unraid) so a future host hang has a durable, off-box log trail; Alloy also collects cluster pod logs via the Kubernetes API, so it's the landing point for future log sources too. See `docs/adr/0002-loki-promtail-logging-stack.md` for the storage/ingress trade-offs and `docs/adr/0003-alloy-replaces-promtail.md` for why Alloy, not Promtail, ships the logs.

## Dashboards

Custom Grafana dashboards are provisioned as code via ConfigMaps (`kubernetes-v2/charts/kube-prometheus-stack/templates/dashboard-*.yaml`), sitting alongside imported community dashboards. First one is Unraid Drives — a single table, one row per physical drive (array disks, parity, cache), showing temperature and capacity together. See `docs/adr/0004-unraid-drive-metric-correlation.md` for how temperature and capacity, which come from two exporters with no shared identifier, are correlated per drive.

## Chart authoring

A minority of apps in `kubernetes-v2/charts/` share a common shape exactly — a single-container web app, one Service/port, HTTP-shaped, ≤1 storage mount, no extra CRs or pod-level fields. Those apps point their `deploy.yaml` at one shared chart, `kubernetes-v2/charts/service`, and differentiate purely through their existing per-app values file. `service` is frozen at its current adopters (`habit-tracker`, `discord-bot`, `cloudflare-ddns`) — apps that don't fit this exact shape (most of the rest: bespoke container topology like `qbittorrent`, multi-Service/multi-port apps, `CronJob`s, apps with extra CRs, etc.) keep their own standalone chart rather than growing `service`'s schema further. See `docs/adr/0006-hand-rolled-service-chart-over-bjws-common.md` for why a third-party library-chart dependency was rejected in favor of `service`.

For the remaining, genuinely uniform *fragments* duplicated across many otherwise-bespoke charts (Traefik `IngressRoute`, `ExternalSecret`, the unreachable-node toleration, the NFS PV+PVC pair), a Helm library chart, `kubernetes-v2/charts/common`, provides shared named templates that any chart can `include`, without forcing convergence on `service`'s full resource-ownership shape. Consuming charts declare it as a pinned local dependency in their own `Chart.yaml`; no vendored `Chart.lock`/`charts/*.tgz` is committed, since ArgoCD's repo-server resolves it live on every sync. See `docs/adr/0007-common-library-chart-for-shared-fragments.md`.

## Disaster recovery

There is no etcd or cluster-state backup. The DR plan is to rebuild the control plane from source of truth: Terraform (`terraform/environments/prod`) recreates the Talos nodes, `kubernetes-v2/bootstrap.sh` reinstalls ArgoCD, and the `ApplicationSet` resyncs every app from git. App data (Longhorn volumes) is backed up separately via Longhorn's recurring jobs to NFS. See `docs/adr/0005-disaster-recovery-rebuild-from-git.md` for why this was chosen over a dedicated backup tool, and the Vault dependency this plan relies on.
