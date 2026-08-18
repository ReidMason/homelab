# 0003: Grafana Alloy replaces Promtail

## Status

Accepted

## Context

Promtail was deployed per [0002](0002-loki-promtail-logging-stack.md) as the
syslog shipper for fern.internal (Unraid). Once fern's remote-syslog was
pointed at it, Promtail's syslog target failed every message with `expecting
a version value in the range 1-999`: Promtail's syslog target only parses
RFC5424, and Unraid's syslogd sends classic BSD-style RFC3164, with no UI
option to change that. This isn't a config mistake to fix — Promtail has no
RFC3164 support at all.

Separately, Promtail reached End-of-Life on 2026-03-02 (LTS ended
2026-02-28) — it was already past that date when this was deployed. No
further updates, including security patches, will ship for it.

Two fixes were considered: an rsyslog relay in front of Promtail to
translate RFC3164 → RFC5424 (the pattern used by community Unraid+Loki
setups), or replacing Promtail with Grafana Alloy, which supports RFC3164
natively via `syslog_format = "rfc3164"`. The relay is the better-trodden
path for this specific Unraid pairing, but it's a workaround bolted onto
EOL software. Alloy is actively developed and was already the flagged
eventual direction.

## Decision

- **Alloy replaces Promtail.** `grafana/alloy` chart, configured via Alloy's
  own component-based config language (River) instead of Promtail's YAML.
  Namespace/release renamed `promtail` → `alloy` throughout.
- **`loki.source.syslog` with `syslog_format = "rfc3164"`** for the Unraid
  listener (TCP, port 1514 — same port/protocol decision as 0002, still
  correct).
- **`loki.source.kubernetes` instead of hostPath tailing** for cluster pod
  logs, replacing Promtail's `kubernetes-pods` scrape job. This component
  reads pod logs through the Kubernetes API instead of mounting
  `/var/log/pods` from the host, which removes two things 0002 needed for
  Promtail: `hostPath` volumes (which required the `promtail` namespace to
  run at the `privileged` Pod Security level) and a DaemonSet (which needed
  the control-plane toleration to also capture `kube1`'s component logs).
- **Deployment, not DaemonSet, `replicas: 1`.** Once log collection no
  longer needs to run per-node, there's nothing left that benefits from a
  DaemonSet — Alloy only needs to run once to serve the syslog listener and
  the Kubernetes-API-based pod log collector.
- **Syslog LoadBalancer service defined as a raw `extraObjects` manifest,**
  not the chart's built-in `service`/`extraPorts` combination. Alloy's chart
  puts every port (including its own metrics/UI port 12345) on a single
  Service with one shared `type`; setting that to `LoadBalancer` would have
  exposed the metrics/UI port externally too. A separate hand-written
  Service, matching the pod selector labels, keeps the main service
  `ClusterIP` and only exposes port 1514.

## Consequences

- The MetalLB IP (`10.128.20.66`) and Prometheus alert shape (`AlloyDown`
  replacing `PromtailDown`) carry over unchanged from 0002, just renamed.
- `loki.source.kubernetes` uses more Kubelet API traffic/CPU than hostPath
  tailing at scale; irrelevant at this cluster's size, but worth knowing if
  log volume grows a lot.
- Alloy's config is River, not YAML — different syntax from every other
  chart in this repo. Future changes to the log pipeline need to reference
  Alloy's component docs, not Promtail's.
