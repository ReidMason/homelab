# 0001: Prometheus alerting conventions

## Status

Accepted

## Context

Alert rules are being added per-app (Unraid, Sonarr, ...) as `PrometheusRule` resources, routed through a single Alertmanager config to Discord. With more apps on the way, the label schema, severity tiers, and routing pattern needed to be settled once instead of re-derived for every new rule set.

## Decision

- **Labels**: every alert rule carries exactly `severity` and `app`. No `team`, `component`, or `environment` labels — single operator, single environment, not worth the overhead.
- **Severity tiers**: two values only, `critical` and `warning`. No `info` tier.
- **Routing**: Alertmanager routes on `severity`. `critical` alerts go to a `discord-critical` receiver, `warning` alerts go to `discord`. Both currently point at the same Discord webhook — the split exists so a real escalation receiver (e.g. Pushover) can be swapped in for `critical` later without restructuring the routing tree.
- **Inhibition**: `UnraidHostDown` (critical) inhibits other `app: unraid` alerts at `severity: warning`, since a down host makes those alerts noisy/misleading rather than informative.
- **`for` durations**: alerts should use a duration that tolerates normal transient blips (minutes, not seconds) unless there's a specific reason for near-instant notification.

## Consequences

- Adding a new app's alerts means picking `critical`/`warning` per rule and setting `app: <name>` — no new label design needed.
- Escalating `critical` alerts to a different channel/service later is a one-line receiver change.
- If a future need arises for finer-grained routing (per-app channels, on-call rotation, multi-environment), this ADR should be revisited rather than layering ad hoc labels onto existing rules.
