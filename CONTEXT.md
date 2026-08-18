# Context

## Alerting

Prometheus `PrometheusRule` resources per app, routed through a single Alertmanager (`kubernetes-v2/charts/kube-prometheus-stack`) to Discord. See `docs/adr/0001-prometheus-alerting-conventions.md` for the label schema, severity tiers, and routing conventions new alert rules should follow.

## Logging

Loki (log store, `kubernetes-v2/charts/loki`) + Alloy (log shipper, `kubernetes-v2/charts/alloy`), queried from Grafana. Started as a syslog receiver for fern.internal (Unraid) so a future host hang has a durable, off-box log trail; Alloy also collects cluster pod logs via the Kubernetes API, so it's the landing point for future log sources too. See `docs/adr/0002-loki-promtail-logging-stack.md` for the storage/ingress trade-offs and `docs/adr/0003-alloy-replaces-promtail.md` for why Alloy, not Promtail, ships the logs.

## Dashboards

Custom Grafana dashboards are provisioned as code via ConfigMaps (`kubernetes-v2/charts/kube-prometheus-stack/templates/dashboard-*.yaml`), sitting alongside imported community dashboards. First one is Unraid Drives — a single table, one row per physical drive (array disks, parity, cache), showing temperature and capacity together. See `docs/adr/0004-unraid-drive-metric-correlation.md` for how temperature and capacity, which come from two exporters with no shared identifier, are correlated per drive.
