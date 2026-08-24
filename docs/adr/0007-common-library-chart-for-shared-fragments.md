# 0007: `common` library chart for shared template fragments, revising ADR-0006's rejection of local library charts

Note: this chart was originally going to be named `_common`, matching how `bjw-s/common` and this repo's own `_helpers.tpl` convention name shared/internal files. That name doesn't work: Helm's chart loader silently skips any file or directory whose basename starts with `_`, which applies to subchart directories under `charts/` too — a dependency named `_common` fetches fine via `helm dependency build` but is then invisible to `helm template`/`helm lint`, which fail with "found in Chart.yaml, but missing in charts/ directory". Confirmed via smoke test (see `seerr`). The chart is `common`, not `_common`.

## Status

Accepted (partially supersedes ADR-0006)

## Context

ADR-0006 established `kubernetes-v2/charts/service`, a standalone owned-resource chart, as the sharing mechanism for apps with a common "web app + storage + ingress" shape. Since then, every further migration onto `service` needed its schema extended (`ExternalSecret` for `discord-bot`, `env[]`/`securityContext` for `cloudflare-ddns`), and several apps (`pihole`, `sonarr`, `jellyfin`, `homeassistant`, `matter-server`, `recyclarr`, `relay`, `nats`) don't fit `service`'s shape at all — for reasons ranging from multi-Service/multi-port topology to non-`Deployment` workload types to pod-level fields (`hostNetwork`) to bundling multiple apps. Full chart-by-chart survey in `.scratch/service-chart-scope/spec.md`.

The pattern: full-resource sharing (one schema owning the actual Deployment/Service/PVC) only works for apps that converge on an identical shape. Most of the remaining chart set doesn't. But several *fragments* within those charts — the Traefik `IngressRoute` block (~20 charts), the `ExternalSecret` block (~14 charts, confirmed uniform shape this session), the `node.kubernetes.io/unreachable` toleration, the NFS PV+PVC pair — are genuinely identical copy-paste across charts regardless of the app's overall shape.

ADR-0006 considered and rejected a local Helm library chart for exactly this kind of first-party template sharing (its option (b)), on the grounds that it carries the same `Chart.lock`/vendored-`.tgz`/`helm dependency update` overhead as the `bjw-s/common` dependency it was replacing.

That premise turned out to be specific to how the dependency is resolved, not inherent to library charts. Checked against ArgoCD's own source (`reposerver/repository/repository.go`): ArgoCD's repo-server does a full git clone of the repo (not a sparse checkout scoped to just the app's `source.path`), and automatically runs `helm dependency build` before templating on every sync, gated by a one-per-checkout marker file rather than an opt-in setting. A chart declaring a local relative dependency (`repository: "file://../common"`) therefore resolves live against `common`'s current source on every sync — no `Chart.lock` or vendored `charts/*.tgz` needs to be committed to git. This removes the specific overhead ADR-0006 rejected. (Confirmed at the source-code level only, not in ArgoCD's published docs — a smoke test on one real chart is planned before relying on this broadly.)

A symlinked `_helpers.tpl` (ADR-0006's option (c), and re-raised this session) was also spiked and confirmed technically viable — ArgoCD's git checkout preserves symlinks, and Helm's template loader resolves them transparently. It was rejected anyway, on taste grounds: it doesn't use Helm's own dependency-declaration mechanism, so nothing in a chart's `Chart.yaml` records that it depends on `common`.

## Decision

Add `kubernetes-v2/charts/common`, a Helm library chart (`type: library`), holding named templates for fragments that are genuinely uniform across many charts regardless of the consuming app's overall shape — starting with `IngressRoute`. Charts that want a fragment declare `common` as a pinned local dependency (`repository: "file://../common"`, exact `version`, no range) in their own `Chart.yaml` and `include` the named template from their own hand-written `templates/`. Each chart keeps full ownership of its own Deployment/pod shape; only the boring, uniform parts are shared.

`service` itself (ADR-0006's decision) is unaffected in shape and is frozen at its current 3 adopters (`habit-tracker`, `discord-bot`, `cloudflare-ddns`) — no further apps are being migrated onto it. `seerr` was reverted to a standalone chart (its pre-ADR-0006 shape) as part of proving out `common`'s IngressRoute fragment, so it's no longer a `service` adopter; see "Smoke test" below. `service` will eventually consume `common`'s fragments internally too, to avoid a third copy of the same IngressRoute/ExternalSecret logic.

Migration of the ~20/~14 existing IngressRoute/ExternalSecret duplicators onto `common` is opportunistic — a chart adopts it when otherwise being touched, not a forced sweep.

## Consequences

- ADR-0006's rejection of `bjw-s/common` (a third-party generic schema) and of a generic `containers: []` list within `service` both still stand — this ADR only reverses the *local library chart* option, on the strength of new information about how the dependency resolves, not a reversal of "avoid generic schemas."
- Each consuming chart gets an explicit, pinned version of `common` in its own `Chart.yaml` — unlike `service`, which is shared/mutable/unversioned per ADR-0006's own noted risk, a `common` consumer's rendered output doesn't change until that chart's pin is deliberately bumped.
- No vendored dependency artifacts are committed to git; correctness depends on ArgoCD's repo-server continuing to auto-run `helm dependency build` against a full checkout. If that behavior changes upstream, every chart depending on `common` would fail to render on next sync — worth revisiting if ArgoCD's dependency-resolution behavior is ever documented differently or changes in an upgrade.
- No bulk-rollout tooling exists yet for bumping `common`'s pin across every consumer at once; a version bump affecting many charts is currently a manual, deliberate multi-file edit.

## Smoke test

Done locally: `common.ingressRoute` built and wired into a restored standalone `seerr` chart (`common` declared as a pinned `file://../common` dependency), verified with `helm dependency build` + `helm template` + `helm lint` against `seerr`'s real prod values — output matches `seerr`'s pre-ADR-0006 rendered IngressRoute exactly. No `Chart.lock`/`charts/*.tgz` committed. Still needs a real ArgoCD sync to confirm the repo-server's auto-`helm dependency build` behavior (this ADR's Context section) end-to-end, not just the local CLI equivalent.
