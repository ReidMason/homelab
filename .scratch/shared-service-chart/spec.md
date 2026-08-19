Status: ready-for-agent

# Shared `service` chart, replacing `bjw-s/common`

See `docs/adr/0006-hand-rolled-service-chart-over-bjws-common.md` for the full decision record and rejected alternatives.

## Problem Statement

As the operator of this homelab cluster, most of the ~32 Helm charts under `kubernetes-v2/charts/` repeat the same boilerplate: a single-container Deployment, a Service, a Traefik `IngressRoute` (duplicated near-verbatim across ~20 charts, ~637 lines total), and either an NFS-backed or storage-class-backed PVC. Maintaining this by copy-paste per chart means fixing a bug or adding a convention (like the `node.kubernetes.io/unreachable` toleration) requires touching every chart individually.

An in-progress attempt to fix this (unstaged changes to `habit-tracker` and `seerr`) adopted `bjw-s/common`, a third-party Helm library chart. That trades copy-paste duplication for a vendored dependency (`Chart.lock`, committed `.tgz`, a `helm dependency update` step after every change) and a generic, deeply-nested values schema built for arbitrary community use — disproportionate overhead for what it saves, and it doesn't address the `IngressRoute` duplication at all.

## Solution

Replace the `bjw-s/common` dependency with one first-party, standalone Helm chart, `kubernetes-v2/charts/service`, covering the actual recurring shape used in this cluster: single-container web app + storage + ingress route + optional metrics sidecar. Apps that fit this shape point at it via the `chart:` field already present in their `deploy.yaml`, and differentiate purely through their existing per-app `values/prod/<app>/values.yaml` — a mechanism the ArgoCD `ApplicationSet` already supports today, so no new dependency, vendoring, or sharing mechanism is introduced.

Apps that don't fit the shape (bespoke multi-container topology, non-standard env wiring) keep their own standalone chart.

## User Stories

1. As the cluster operator, I want a single shared chart for the common "web app + storage + ingress" shape, so that fixing a bug or adding a convention (e.g. a new toleration) only requires touching one chart instead of N.
2. As the cluster operator, I want the shared chart to have zero third-party or vendored dependencies, so that I don't inherit a `Chart.lock`/`helm dependency update` workflow for code I fully own.
3. As the cluster operator, I want `habit-tracker` and `seerr` reverted off `bjw-s/common` and onto the new shared chart, so the cluster isn't left with one dependency-based chart and 30 hand-rolled ones.
4. As the cluster operator, I want the shared chart to support NFS-backed PV+PVC storage (as `habit-tracker`/`seerr` need), so that app data on `fern.internal` NFS shares keeps working after migration.
5. As the cluster operator, I want the shared chart to also support plain `storageClassName`-backed PVC storage (as several existing charts use, e.g. `qbittorrent`'s pattern), so that apps using Longhorn-backed storage can adopt the chart too.
6. As the cluster operator, I want the shared chart to render a Traefik `IngressRoute` from the existing `homelab.ingressRoute.*` values shape (host, entryPoints, middleware, forwardAuth), so that the largest source of duplication (~637 lines across ~20 charts) gets addressed as apps migrate.
7. As the cluster operator, I want optional readiness/liveness probes with a configurable path, so that apps like `seerr` (which needs `/api/v1/settings/public`, not the container's root path) aren't blocked from adopting the chart.
8. As the cluster operator, I want an optional list of secret-sourced env vars (`{envName, secretKey}` against one `ExternalSecret` per app), so that apps like `discord-bot`/`cloudflare-ddns`/`sonarr` that inject a token or API key from a secret can adopt the chart.
9. As the cluster operator, I want an optional `metricsSidecar` block (`{image, port, apiKeySecret}`) matching the existing `sonarr`/`exportarr` pattern, so that apps needing a metrics-exporter sidecar can adopt the chart without the chart supporting arbitrary multi-container pods.
10. As the cluster operator, I want the chart to explicitly support only one main container plus the one optional metrics sidecar, so that apps needing genuine multi-container topology (e.g. `qbittorrent`'s VPN sidecar + multiple app containers) are steered toward keeping their own chart rather than forcing a generic, more complex schema onto every consumer.
11. As the cluster operator, I want migration to the shared chart to be incremental (opportunistic, as apps are touched), so that this isn't a forced, high-blast-radius migration of all 32 charts at once.
12. As a future maintainer (human or agent) touching chart #33, I want an ADR explaining why `bjw-s/common` and a local library-chart dependency were both rejected, so the reasoning isn't silently lost.

## Implementation Decisions

- **New chart**: `kubernetes-v2/charts/service`. Standalone chart — no `dependencies:` entry, no `Chart.lock`, no vendored `charts/` subdirectory. Templates live directly in `kubernetes-v2/charts/service/templates/`.
- **Adoption mechanism**: existing `deploy.yaml` per app (`kubernetes-v2/values/prod/<app>/deploy.yaml`) already declares `chart: <name>`, and the ApplicationSet already resolves the Helm chart path from that field and merges the chart's default `values.yaml` with `kubernetes-v2/values/prod/<app>/values.yaml`. Apps adopt `service` by changing `chart:` to `service`; no ApplicationSet or `argocd/` changes are required.
- **Revert scope**: remove the `bjw-s/common` dependency from `habit-tracker` and `seerr` — delete `Chart.lock`, `charts/`, `templates/common.yaml`, and the `dependencies:` block in `Chart.yaml` for both. Convert both apps' `deploy.yaml`/`values.yaml` to use `chart: service` with the new flat schema instead of restoring their old per-app `deployment.yaml`/`service.yaml`.
- **Values schema** (flat, with light nesting where it groups related fields — e.g. `image: {repository, tag}`, not a `controllers.X.containers.Y` style deep hierarchy):
  - `image.repository`, `image.tag`
  - `containerPort`
  - `service.port` (Service port, defaults sensible for HTTP apps)
  - `storage` — one of two opt-in shapes:
    - NFS: `storage.nfs.{enabled, server, path, size, claimName}` — chart renders a PV + PVC pair, mirroring the current `habit-tracker`/`seerr` pattern (PV named by `{{ .Release.Namespace }}-<claimName>`, `ReadWriteMany`, `Retain` reclaim policy).
    - StorageClass: `storage.pvc.{enabled, storageClassName, size, claimName}` — chart renders a plain PVC only (no PV), mirroring the `qbittorrent`-style pattern.
    - Mount path for the main container's volume: `storage.mountPath`.
  - `ingressRoute.*` — reuse the existing shape from current charts verbatim: `enabled, host, entryPoints[], middleware.{enabled, name, namespace}, forwardAuth.{enabled, outpostServiceName, outpostServiceNamespace, outpostServicePort, middlewareName, middlewareNamespace}`.
  - `probes.{enabled, path}` — when enabled, renders both readinessProbe and livenessProbe against `containerPort` and `probes.path`, with the same delay/period/timeout defaults currently hardcoded in `seerr`'s old `deployment.yaml` (readiness: 60s initial/15s period/3s timeout; liveness: 20s initial/15s period/3s timeout).
  - `secretEnv[]` — list of `{envName, secretKey}`, each rendered as an env var sourced via `secretKeyRef` against one `externalSecret.name` value (single `ExternalSecret` per app, matching the existing `homelab.externalSecret.name` convention).
  - `metricsSidecar.{enabled, image.repository, image.tag, port, args[], apiKeySecret.name, apiKeySecret.key}` — when enabled, renders exactly one additional container, matching `sonarr`'s current `exportarr` block shape.
  - `tolerations` — default to the standard `node.kubernetes.io/unreachable` / `NoExecute` / `10s` toleration used across all current charts; overridable if a future app needs something different.
- **Resource naming**: templates use `.Release.Name` (which the ApplicationSet already sets to the app's folder name, e.g. `habit-tracker`) for resource names instead of hardcoding an app name string, since the same chart now backs multiple releases.
- **Out of scope for `service`** (opt-out triggers — app keeps/gets its own chart instead): more than one main container, sidecars other than the single `metricsSidecar` slot, multiple `ExternalSecret` sources, custom volume mounts beyond the one storage block, non-HTTP services, anything needing raw pod-spec fields not covered above (e.g. `securityContext.fsGroup`, used by the old `seerr` chart — confirm during implementation whether this needs to fold into the flat schema as a `storage.fsGroup`-style field or whether `seerr` can drop it).
- **Rollout**: only `habit-tracker` and `seerr` are migrated as part of this spec (reverting the in-progress `bjw-s/common` change). Migrating other existing charts (`radarr`, `sonarr`, `discord-bot`, `cloudflare-ddns`, etc.) onto `service` is out of scope here and happens opportunistically later, each as its own small change.
- **Documentation**: `docs/adr/0006-hand-rolled-service-chart-over-bjws-common.md` and the `CONTEXT.md` "Chart authoring" section already exist (written as part of this spec's authoring) and should not need further changes unless implementation reveals a materially different shape than described above — if so, update the ADR's Decision section to match reality.

## Testing Decisions

- Primary seam: `helm template` rendering. No cluster access is required or appropriate (per this repo's read-only-kubectl posture) — correctness is verified by rendering the chart against representative fixture values files and asserting on the resulting Kubernetes manifests (YAML structure, not just "it renders without error").
- Fixture values files to cover, each exercising a distinct opt-in combination:
  1. Minimal: image + containerPort only, no storage/ingress/probes/secrets/sidecar — asserts Deployment + Service render, nothing else does.
  2. NFS storage + IngressRoute (mirrors `habit-tracker` post-migration).
  3. StorageClass PVC + IngressRoute + probes + secretEnv (mirrors `seerr` post-migration, plus the storage-class variant not yet used by any real app).
  4. All blocks enabled including `metricsSidecar`, to verify the two-container case renders both containers correctly and doesn't leak metrics-sidecar config onto the main container.
- Assert specifically on: resource names being derived from release name (not hardcoded), the `ingressRoute.forwardAuth`/`middleware` conditional blocks matching the existing per-chart output byte-for-byte where the source values are equivalent (regression check against current `radarr`/`sonarr`-style `ingressroute.yaml` output), and that disabled optional blocks (storage, probes, secretEnv, metricsSidecar) produce no trace of the corresponding resource/field.
- No prior Helm-testing prior art exists in this repo (`helm unittest`/`helm-template`-diffing plugin is not currently installed) — implementation should pick a lightweight approach (e.g. `helm template` + snapshot comparison via a simple shell/CI script, or the `helm unittest` plugin if it's acceptable to add as a dev-only tool). This choice is left to the implementer; note it explicitly in the PR since it's new tooling for the repo.
- Manual verification: after automated rendering tests pass, a manual `kubectl diff`-style review (read-only, consistent with the no-one-off-fix-commands / read-only-kubectl constraints already in effect for this repo) of `habit-tracker` and `seerr` before considering the migration complete — this is a human/agent-in-the-loop step, not something to automate.

## Out of Scope

- Migrating any chart other than `habit-tracker` and `seerr` onto `service`.
- Generic multi-container support (a `containers: []` list) — explicitly rejected in ADR-0006.
- Changing the ArgoCD `ApplicationSet` or the `chart:`/values-merge mechanism in `deploy.yaml` — it already supports this use case unmodified.
- Adding a version pin or per-app opt-out mechanism for `service` template changes (e.g. no "pin to a git ref" scheme) — a template change affects all adopters on next sync, accepted as a consequence in ADR-0006.
- Vault, ExternalSecret operator setup, Longhorn StorageClass provisioning, or any other infrastructure this chart merely references but doesn't own.

## Further Notes

- `qbittorrent` is the concrete example (VPN sidecar + `qbittorrent` + `prowlarr` + `flaresolverr`) of an app that stays on its own standalone chart — no changes needed to it as part of this work.
- If a second app later surfaces a genuine need for more than one non-metrics sidecar, ADR-0006's rejection of generic multi-container support should be revisited then, not preemptively solved now.
- The `.scratch/bjw-s-common-library-trial/` directory (currently just an empty `issues/` folder) appears to be the tracker entry for the original `bjw-s/common` trial this spec supersedes; it can likely be cleaned up once this spec's issues are filed, but that's left to the person/agent doing issue hygiene, not part of this spec.
