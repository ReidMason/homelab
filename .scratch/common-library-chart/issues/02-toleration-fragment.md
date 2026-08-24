# 02 — `common.toleration` fragment

**What to build:** A named template `common.toleration` in `kubernetes-v2/charts/common/templates/_toleration.tpl`, rendering the standard `node.kubernetes.io/unreachable`/`NoExecute` pod toleration block duplicated across 27 charts today. Call signature: `include "common.toleration" (dict "tolerationSeconds" <int>)`. When `tolerationSeconds` is omitted or nil, default to `10` (the value used by ~24 of the 27 current duplicators). The output is the `tolerations:` YAML list (a single entry, starting with `- key: node.kubernetes.io/unreachable`), meant to be included directly under a pod spec's `tolerations:` key, matching how every current chart writes it inline.

Three current charts (`pihole`, `portainer`, `valkey`) use `tolerationSeconds: 0` instead of `10` — the template must support that as an explicit override, not just the default.

Follow the same file/definition pattern already established by `common/templates/_ingressroute.tpl` (see `common.ingressRoute` for the convention: doc comment above `{{- define ... -}}`, dict-based call signature).

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `include "common.toleration" (dict)` (no `tolerationSeconds` key, or nil) renders `tolerationSeconds: 10`
- [ ] `include "common.toleration" (dict "tolerationSeconds" 0)` renders `tolerationSeconds: 0`
- [ ] Rendered output matches the existing inline block's structure exactly (`key: node.kubernetes.io/unreachable`, `effect: NoExecute`, `tolerationSeconds: <n>`) when diffed against e.g. `radarr`'s current `deployment.yaml` toleration block
- [ ] `kubernetes-v2/charts/common/Chart.yaml`'s version is bumped (this is an addition to an existing chart's public template surface)
