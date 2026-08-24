Status: ready-for-agent

# `common` library chart: toleration and ExternalSecret fragments

See `docs/adr/0007-common-library-chart-for-shared-fragments.md` for why this mechanism exists, and `.scratch/service-chart-scope/spec.md` for the fuller architectural discussion (two-track model, `service`'s deferred fate, alternatives considered and rejected) this spec narrows down into buildable work.

## Problem Statement

Two more fragments are duplicated across many otherwise-bespoke charts in `kubernetes-v2/charts/`, the same way the Traefik `IngressRoute` block was before it was extracted into `kubernetes-v2/charts/common`:

- The `node.kubernetes.io/unreachable`/`NoExecute` pod toleration block, duplicated across 27 charts.
- The `ExternalSecret` custom resource, duplicated across 14 charts, in a uniform shape (one remote Vault key, one `ClusterSecretStore`, N properties mapped to secret keys).

Every one of these is hand-copied per chart today, and every future chart that needs Vault-sourced secrets or the standard toleration has to copy it again.

Separately, building `common.ingressRoute` this session surfaced a real gap: nothing stops the `Chart.lock`/`charts/*.tgz` artifacts that `helm dependency build` generates locally from being accidentally committed, even though the project's decision (ADR-0007) is that nothing vendored should ever be committed.

## Solution

Add two more named templates to the existing `kubernetes-v2/charts/common` library chart — `common.toleration` and `common.externalSecret` — matching the exact shapes already duplicated across the fleet, so future consuming charts `include` them instead of copy-pasting. Add repo-side `.gitignore` protection so `helm dependency build`'s local output can never be accidentally staged.

This does not migrate any of the 27/14 existing duplicators onto the new fragments — per the standing decision in `.scratch/service-chart-scope/spec.md`, migration of existing users is opportunistic only, not a forced sweep. This spec only makes the fragments exist and be correct.

## User Stories

1. As the homelab operator, I want a `common.toleration` named template, so that a new chart needing the standard unreachable-node toleration can include one line instead of copying a 5-line block.
2. As the homelab operator, I want `common.toleration` to accept `tolerationSeconds` as a parameter, so that it still fits the 3 existing charts (`pihole`, `portainer`, `valkey`) that intentionally use `0` instead of the `10` most charts use.
3. As the homelab operator, I want `common.toleration` to default `tolerationSeconds` to `10` when the caller doesn't specify it, so that the common case stays a one-line include with no boilerplate dict.
4. As the homelab operator, I want a `common.externalSecret` named template, so that a new chart needing Vault-sourced secrets can include one call instead of copying the ~26-line `ExternalSecret` block.
5. As the homelab operator, I want `common.externalSecret` to accept the same parameters `service`'s existing `externalsecret.yaml` already exposes (`name`, `remoteKey`, `refreshInterval`, `clusterSecretStoreName`, and a list of `{secretKey, property}` entries), so that its output is a drop-in match for the shape already proven correct in `service` and duplicated across the other 13 charts.
6. As the homelab operator, I want `common.externalSecret`'s rendered output to be byte-identical to `service`'s current `externalsecret.yaml` output given equivalent values, so that `service` can safely switch to consuming this fragment internally later without changing behavior for its existing adopters.
7. As the homelab operator, I want `Chart.lock` and `charts/*.tgz` ignored by git wherever a chart declares a local `common` dependency, so that a stray `git add` (or an editor/IDE auto-stage) can't accidentally commit generated, non-source artifacts that ADR-0007 explicitly decided should never be vendored.
8. As the homelab operator, I want the `.gitignore` rule scoped so it doesn't need updating every time a new chart adopts `common`, so that the protection is durable as more charts opt in over time.

## Implementation Decisions

- Both new fragments live in `kubernetes-v2/charts/common/templates/`, as separate `_toleration.tpl`/`_externalsecret.tpl` files (or similarly named), following the pattern already established by `_ingressroute.tpl` — one file per fragment, `{{- define "common.<name>" -}}` blocks.
- `common.toleration` renders a single pod-spec `tolerations:` list entry (the `node.kubernetes.io/unreachable`/`NoExecute` block), called with a dict argument. Signature: `include "common.toleration" (dict "tolerationSeconds" <int>)`. When `tolerationSeconds` is omitted/nil, default to `10` (Helm's `default` function). Output is the `tolerations:` YAML list (starting with `- key: node.kubernetes.io/unreachable`), meant to be included directly under a pod spec's `tolerations:` key — matches how every existing consumer currently writes it inline under `spec.template.spec.tolerations`.
- `common.externalSecret` renders one `ExternalSecret` custom resource, matching `service/templates/externalsecret.yaml`'s exact shape and field names (`apiVersion: external-secrets.io/v1`, `kind: ExternalSecret`, `spec.refreshInterval`, `spec.secretStoreRef.{name, kind: ClusterSecretStore}`, `spec.target.{name, creationPolicy: Owner, deletionPolicy: Retain}`, `spec.data[].{secretKey, remoteRef.{key, property, conversionStrategy: Default, decodingStrategy: None, metadataPolicy: None, nullBytePolicy: Ignore}}`). Signature: `include "common.externalSecret" (dict "name" ... "remoteKey" ... "refreshInterval" ... "clusterSecretStoreName" ... "secretEnv" <list of {secretKey, property}>)`. Guarded the same way `service`'s version is (`if and .enabled .remoteKey`) — caller passes `enabled` in the dict.
- No changes to `service`'s own templates in this spec — `service` continues to render its own inline `externalsecret.yaml`/toleration block for now. Refactoring `service` to consume `common` internally is explicitly deferred (see `.scratch/service-chart-scope/spec.md`, `service`'s fate decision).
- `.gitignore` addition: a repo-root or `kubernetes-v2/charts/`-scoped pattern matching `charts/*.tgz` and `Chart.lock` wherever they appear under `kubernetes-v2/charts/*/`, so it covers every current and future chart directory that declares a `common` (or any other) local dependency without needing a per-chart entry.
- No values.schema.json, no scaffold tooling, no migration of existing IngressRoute/toleration/ExternalSecret duplicators — all explicitly out of scope per the parent spec's decisions.

## Testing Decisions

Explicitly skipped for this round, per direct instruction. `common.ingressRoute` also currently has no automated tests — this spec does not add a test harness for any of `common`'s fragments. If this changes, prior art for the seam is `kubernetes-v2/charts/service/tests/` (fixture + snapshot `helm template` diffing via `render.sh`), adapted for a library chart via a small harness chart under `common/tests/` that depends on `common` and includes each fragment (library charts can't be `helm template`'d directly).

## Out of Scope

- Any test harness or fixtures for `common`'s fragments (including `common.ingressRoute`, which also has none today).
- Migrating any of the 27 (`toleration`) / 14 (`ExternalSecret`) existing duplicators onto the new fragments — opportunistic only, per standing decision.
- Refactoring `service` to consume `common` fragments internally.
- The NFS PV+PVC pair fragment (mentioned as a future candidate in `.scratch/service-chart-scope/spec.md` but not decided as in-scope for this round).
- `values.schema.json` / any typed-values validation layer.
- Any scaffold/generator tooling for new services.
- A typed manifest generator (Go/cdk8s/KCL/CUE/Pulumi) — considered and rejected this session; see `.scratch/service-chart-scope/spec.md`.

## Further Notes

- `pihole`, `portainer`, and `valkey` are the only 3 of the 27 toleration-duplicating charts using `tolerationSeconds: 0` instead of `10` — confirmed via direct grep across the fleet this session. Any future migration of those 3 onto `common.toleration` must pass `tolerationSeconds: 0` explicitly.
- `service`'s current `externalsecret.yaml` is the reference implementation for `common.externalSecret`'s expected output shape — it's the one place this shape has already been built and is live for `discord-bot`/`cloudflare-ddns`.
