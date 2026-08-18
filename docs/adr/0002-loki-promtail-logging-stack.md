# 0002: Loki + Promtail logging stack

## Status

Superseded by [0003](0003-alloy-replaces-promtail.md) — Promtail's syslog
target turned out to only support RFC5424, and Unraid sends RFC3164; Promtail
was also already past its EOL date. The Loki decisions below (monolithic +
filesystem storage, no gateway, dedicated LoadBalancer IP, TCP-only syslog)
are unaffected and still stand.

## Context

fern.internal (Unraid) hung unreachable and was hard-power-cycled; its syslog
is RAM-only, so the crash left no diagnosable trail. Its remote-syslog target
was also stale (`10.128.0.100`, nothing listens there). We need a durable
place for fern's syslog to land, running on separate hardware/failure domain
from fern itself — the `homelab` k8s cluster (`ivy`, Proxmox, different box
and subnet). Scoped as an initial, syslog-only pass; more log sources
expected later.

## Decision

- **Loki, monolithic + filesystem storage, no gateway.** `grafana/loki`
  chart, `deploymentMode: SingleBinary`, `loki.storage.type: filesystem`
  (not the chart's default `s3`) with a longhorn PVC. `gateway.enabled:
  false` — Promtail pushes straight to the `loki` service on port 3100.
  At single-tenant homelab scale, the nginx gateway and object-storage
  backend the chart defaults to are unnecessary moving parts.
- **Promtail over Alloy.** Promtail is in Grafana's maintenance mode
  (superseded by Alloy) but was chosen for this pass for its simplicity as a
  pure syslog shipper. Worth reconsidering Alloy once more log sources are
  pushed to this stack.
- **Syslog over TCP, not UDP.** `grafana/loki` issue #6772 documents UDP
  syslog jobs not reliably delivering to Loki. Promtail's syslog scrape job
  listens on TCP only; Unraid's remote-syslog config must match.
- **Dedicated LoadBalancer IP for syslog ingress, not Traefik.** This repo
  has precedent for TCP passthrough via Traefik `IngressRouteTCP`
  (postgres, nats, valkey), but all of it is `HostSNI`-based, relying on the
  proxied protocol doing its own TLS handshake so Traefik can route on SNI
  without decrypting. Plaintext syslog has no TLS/SNI to route on. Making it
  work through Traefik would mean adding a new non-TLS TCP entrypoint to the
  shared Traefik deployment every other app depends on, with no precedent in
  this repo. A dedicated LoadBalancer IP (`10.128.20.66` from the MetalLB
  prod pool) on Promtail's own service is isolated and costs one IP from a
  pool that had room.
- **Separate `loki`/`promtail` namespaces.** Forced by this repo's
  ArgoCD ApplicationSet model (one `values/prod/<name>/` dir = one namespace =
  one Helm release); they can't share a namespace without sharing a
  directory, which the glob-per-dir model doesn't support. Promtail reaches
  Loki cross-namespace via `loki.loki.svc.cluster.local:3100`.

## Consequences

- Adding further log sources later (more Promtail scrape jobs, or other
  apps' Promtail/Alloy instances) just needs to know Loki's cluster-internal
  push URL — no gateway auth/routing to configure.
- If ingest volume or multi-tenancy needs grow past what filesystem storage
  and monolithic mode comfortably handle, revisit storage type
  (filesystem → S3/minio) and deployment mode (SingleBinary → distributed)
  together — the chart supports migrating both.
- The MetalLB pool has one fewer free IP (`10.128.20.66` now claimed,
  leaving `.67`-`.69`).
