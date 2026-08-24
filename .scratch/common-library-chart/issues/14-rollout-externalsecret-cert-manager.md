# 14 — Roll out common.externalSecret to cert-manager

**What to build:** `cert-manager`'s `templates/cloudflare-externalsecret.yaml` is replaced with a call to `common.externalSecret`. `Chart.yaml` declares `common` as a `file://../common` dependency.

This ticket resolves a pre-existing inconsistency, not a routine swap. The current template hardcodes `metadata.name: cf-cloudflare-token`, while `spec.target.name` is driven by `.Values.homelab.cloudflare.externalSecret.name` (currently `cloudflare-token-secret` in prod values) — the `ExternalSecret` resource's own name and the `Secret` it creates already don't match today. `common.externalSecret` uses a single `name` input for both `metadata.name` and `target.name`, so adopting it will rename the `ExternalSecret` resource itself (Kubernetes will delete the old-named object and create a new one — not an in-place rename). The current template also sets an explicit `metadata.namespace: {{ .Release.Namespace }}`, which `common.externalSecret` does not render (relies on Helm's implicit release-namespace behavior).

**Blocked by:** None — can start immediately, but requires a decision before implementing (see below), not just a mechanical swap.

**Status:** ready-for-agent

- [ ] Explicit decision made and recorded: is renaming the `ExternalSecret` object from `cf-cloudflare-token` to whatever `.Values...name` is set to (prod: `cloudflare-token-secret`) acceptable, or does `common.externalSecret` need a `metadataName` override param to preserve `cf-cloudflare-token` as the resource name while keeping `target.name` separate?
- [ ] Explicit decision made and recorded: does dropping the explicit `metadata.namespace` (relying on Helm's implicit release namespace) reproduce current behavior, confirmed against how `cert-manager` is actually deployed (release namespace vs. target namespace)?
- [ ] `cert-manager/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [ ] `templates/cloudflare-externalsecret.yaml` calls `common.externalSecret` (or documents why it can't, if the decisions above rule it out)
- [ ] `helm template` output reviewed and diffed against pre-migration output; any differences (the resource rename, namespace handling) are the ones explicitly decided above, nothing incidental
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed

**Notes:**

Flagged during survey: unlike the other rollout tickets, this one surfaces and must resolve a real pre-existing bug (name mismatch) rather than just relocating working code.
