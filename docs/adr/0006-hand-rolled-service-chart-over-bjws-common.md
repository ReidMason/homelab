# 0006: Hand-rolled `service` chart replaces `bjw-s/common` for deployment boilerplate

## Status

Accepted

## Context

Two of 32 charts (`habit-tracker`, `seerr`) were converted to depend on `bjw-s/common`, a third-party Helm library chart, to remove duplicated `deployment.yaml`/`service.yaml` boilerplate (~65-130 lines per chart). This pulled in a vendored 120K dependency (`Chart.lock`, `charts/*.tgz`) and a generic, deeply-nested values schema (`controllers.<name>.containers.<name>...`) designed for arbitrary community use, for a savings of a few dozen lines per chart.

Two duplication patterns exist across the chart set:

- **Deployment/Service/PVC boilerplate** — what `bjw-s/common` targets. Present in most charts.
- **IngressRoute (Traefik) boilerplate** — ~30 near-identical lines duplicated across ~20 charts (~637 lines total), varying only by app name. `bjw-s/common` does not address this at all, since it's a Traefik-specific CRD, not something the library chart generates.

No ADR previously recorded the decision to adopt `bjw-s/common`; this ADR both reverses that adoption and records what replaces it.

Considered alternatives:

- **(a) Keep `bjw-s/common`.** Rejected: the vendoring workflow (`Chart.lock`, committed `.tgz`, re-running `helm dependency update` after every change) is disproportionate overhead for the line count saved, and the schema's generality (arbitrary multi-container support, ServiceAccount toggles, etc.) is unused surface area this repo doesn't need.
- **(b) A local Helm library chart** (own code, added via `dependencies:` in each consuming chart's `Chart.yaml`). Rejected: mechanically identical overhead to (a) — same `Chart.lock`/vendoring/`helm dependency update` cycle — just for first-party code. Doesn't address the actual complaint, which was the workflow, not the code's origin.
- **(c) Symlinked shared `_helpers.tpl`** file included into each consuming chart's `templates/` directory. Considered a viable no-dependency option, but superseded by (d) once it was noticed that the existing ArgoCD `ApplicationSet` already resolves each app's chart path from an explicit `chart:` field in `values/prod/<app>/deploy.yaml`, and already merges the chart's default `values.yaml` with a per-app override file. No new sharing mechanism was needed at all.
- **(d) One real, reusable Helm chart, `kubernetes-v2/charts/service`.** Chosen. Apps that fit the common shape point `chart: service` at it instead of having their own chart directory; per-app differences are expressed entirely through the existing per-app values-file mechanism. No Helm `dependencies:`, no vendoring, no lock file, no symlinks.
- **(e) Generic `containers: []` list** to support arbitrary multi-container pods within `service`. Rejected: it would force every consumer (including single-container apps) into a nested schema, push volume-mount wiring and Service port-targeting back onto the author, and the one concrete candidate (`qbittorrent`: `gluetun` + `qbittorrent` + `prowlarr` + `flaresolverr`) doesn't share a uniform container shape anyway — a generic loop wouldn't dedupe anything for it. Same premature-generalization failure mode being rejected in (a)/(b).

## Decision

`bjw-s/common` is removed from `habit-tracker` and `seerr`. A new chart, `kubernetes-v2/charts/service`, is added as the shared template for apps that fit a common "web app + storage + ingress" shape. It is a normal, standalone Helm chart — not a library chart, not a dependency of anything. Apps opt in by setting `chart: service` in their `deploy.yaml` and supplying a per-app `values/prod/<app>/values.yaml`.

`service` covers, behind a flat values schema (light nesting permitted where it aids expansion), for a **single main container**:

- Deployment + Service (image, port, standard `node.kubernetes.io/unreachable` toleration)
- Storage: either NFS-backed PV+PVC or plain `storageClassName`-backed PVC, as alternate opt-in blocks
- IngressRoute (Traefik), reusing the existing `homelab.ingressRoute.*` shape (host, entryPoints, middleware, forwardAuth)
- Readiness/liveness probes, with a configurable path
- Secret-sourced env vars, as a values-driven list of `{envName, secretKey, property}` against one `ExternalSecret` per app, which `service` renders itself (`externalSecret.{enabled, name, remoteKey, refreshInterval, clusterSecretStoreName}`) — the chart references but does not provision the underlying Vault/`ClusterSecretStore` infrastructure, only the per-app `ExternalSecret` custom resource
- An optional `metricsSidecar` block (`{image, port, apiKeySecret}`) — a single dedicated second-container slot matching the existing `sonarr` `exportarr` pattern exactly, not a generic multi-container mechanism
- Plain literal-value env vars, as a values-driven list of `{name, value}` (`env[]`), rendered alongside `secretEnv` in the same container `env:` block
- An opt-in container-level `securityContext` passthrough (`securityContext: {}`, rendered verbatim via `toYaml`) for apps needing hardening (read-only root filesystem, dropped capabilities, non-root UID/GID, etc.) — a raw passthrough rather than named fields, so it isn't limited to whichever fields the first consumer happened to need

Anything beyond this shape (multi-container beyond the one metrics sidecar, bespoke env wiring beyond a flat literal/secret list, sidecars other than metrics) is explicitly out of scope. Such apps keep or get their own standalone chart, same as `authentik`, `postgres`, and `qbittorrent` today.

Rollout is incremental: apps are converted to `service` opportunistically as they're touched, not as a forced migration of all 32 charts.

## Consequences

- No third-party or vendored dependency for this repo's own deployment boilerplate; no `Chart.lock`/`charts/*.tgz` build step to maintain.
- `service` is shared, mutable, unversioned per-consumer: a template change affects every app using it on next ArgoCD sync (the `ApplicationSet` already runs with `selfHeal: true`). There is no per-app pin to roll back individually — acceptable here since the templates are simple and homelab-scale, but worth remembering if `service` ever grows riskier logic.
- The IngressRoute duplication (~637 lines across ~20 charts) gets addressed as those apps migrate to `service`, which `bjw-s/common` alone would never have done.
- Apps with genuinely bespoke container topology (`qbittorrent` today; possibly others later) stay on standalone charts indefinitely — `service` is deliberately not trying to be a universal chart.
- If a second app surfaces a real need for more than one non-metrics sidecar, revisit the multi-container rejection in (e); one data point (`qbittorrent`) was judged insufficient to generalize for.
