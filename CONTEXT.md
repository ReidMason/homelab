# Context

## Alerting

Prometheus `PrometheusRule` resources per app, routed through a single Alertmanager (`kubernetes-v2/charts/kube-prometheus-stack`) to Discord. See `docs/adr/0001-prometheus-alerting-conventions.md` for the label schema, severity tiers, and routing conventions new alert rules should follow.

## Logging

Loki (log store, `kubernetes-v2/charts/loki`) + Alloy (log shipper, `kubernetes-v2/charts/alloy`), queried from Grafana. Started as a syslog receiver for fern.internal (Unraid) so a future host hang has a durable, off-box log trail; Alloy also collects cluster pod logs via the Kubernetes API, so it's the landing point for future log sources too. See `docs/adr/0002-loki-promtail-logging-stack.md` for the storage/ingress trade-offs and `docs/adr/0003-alloy-replaces-promtail.md` for why Alloy, not Promtail, ships the logs.

## Dashboards

Custom Grafana dashboards are provisioned as code via ConfigMaps (`kubernetes-v2/charts/kube-prometheus-stack/templates/dashboard-*.yaml`), sitting alongside imported community dashboards. First one is Unraid Drives — a single table, one row per physical drive (array disks, parity, cache), showing temperature and capacity together. See `docs/adr/0004-unraid-drive-metric-correlation.md` for how temperature and capacity, which come from two exporters with no shared identifier, are correlated per drive.

## Chart authoring

Most apps in `kubernetes-v2/charts/` share a common shape — a single-container web app with some storage and a Traefik `IngressRoute`. Rather than duplicating that boilerplate per chart (or pulling in a third-party library chart), apps that fit the shape point their `deploy.yaml` at one shared chart, `kubernetes-v2/charts/service`, and differentiate purely through their existing per-app values file. Apps with bespoke container topology (e.g. `qbittorrent`'s VPN sidecar + multiple app containers) keep their own standalone chart. See `docs/adr/0006-hand-rolled-service-chart-over-bjws-common.md` for why a third-party/library-chart dependency was rejected in favor of this.

## Disaster recovery

There is no etcd or cluster-state backup. The DR plan is to rebuild the control plane from source of truth: Terraform (`terraform/environments/prod`) recreates the Talos nodes, `kubernetes-v2/bootstrap.sh` reinstalls ArgoCD, and the `ApplicationSet` resyncs every app from git. App data (Longhorn volumes) is backed up separately via Longhorn's recurring jobs to NFS. See `docs/adr/0005-disaster-recovery-rebuild-from-git.md` for why this was chosen over a dedicated backup tool, and the Vault dependency this plan relies on.
