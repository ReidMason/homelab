# 13 — Roll out common.externalSecret to traefik

**What to build:** `traefik`'s `templates/external-secret.yaml` is replaced with a call to `common.externalSecret`. `Chart.yaml` declares `common` as a `file://../common` dependency.

This is **not a byte-identical swap** — `traefik`'s current template is missing fields every other chart's ExternalSecret has: `deletionPolicy: Retain` on `target`, and `conversionStrategy`/`decodingStrategy`/`metadataPolicy`/`nullBytePolicy` on `data[].remoteRef`. Its enable-guard is also `if .Values.homelab.externalSecret.enabled` only, unlike every other chart's `if and ...enabled ...remoteKey`. Adopting `common.externalSecret` fixes both — bringing `traefik` in line with the rest of the fleet — but the rendered manifest will differ from what's currently deployed (though functionally equivalent, since these are ESO's own defaults for the omitted fields).

**Blocked by:** None — can start immediately, but confirm the "functionally equivalent" claim before treating this as routine.

**Status:** ready-for-agent

- [ ] `traefik/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [ ] `templates/external-secret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] Confirmed via ESO docs/behavior that the newly-added fields (`deletionPolicy: Retain`, `conversionStrategy: Default`, `decodingStrategy: None`, `metadataPolicy: None`, `nullBytePolicy: Ignore`) match ESO's own defaults for a resource that previously omitted them — i.e. no functional change to the running Secret, only the manifest text
- [ ] Confirmed the guard change (now requiring `remoteKey` to be set, not just `enabled`) doesn't break `traefik`'s current deployed config (i.e. `remoteKey` is in fact already set wherever `enabled: true` is used)
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed

**Notes:**

Flagged during survey: this ticket knowingly changes rendered output (fixing a latent inconsistency), unlike the other rollout tickets in this batch which are meant to be no-op swaps.
