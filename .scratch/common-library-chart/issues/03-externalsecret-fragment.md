# 03 — `common.externalSecret` fragment

**What to build:** A named template `common.externalSecret` in `kubernetes-v2/charts/common/templates/_externalsecret.tpl`, rendering an `ExternalSecret` custom resource matching the shape already implemented in `kubernetes-v2/charts/service/templates/externalsecret.yaml` byte-for-byte given equivalent inputs — `service`'s version is the reference implementation, already live for `discord-bot`/`cloudflare-ddns` and confirmed uniform across the other 13 charts duplicating this shape.

Call signature: `include "common.externalSecret" (dict "name" ... "remoteKey" ... "refreshInterval" ... "clusterSecretStoreName" ... "secretEnv" <list of {secretKey, property}> "enabled" <bool>)`. Guard rendering on `and .enabled .remoteKey`, matching `service`'s current guard (`if and .Values.externalSecret.enabled .Values.externalSecret.remoteKey`).

Fixed/structural fields that don't vary per caller (carry over from `service`'s implementation as-is, not parameters): `apiVersion: external-secrets.io/v1`, `kind: ClusterSecretStore` for the store ref, `target.creationPolicy: Owner`, `target.deletionPolicy: Retain`, and the `remoteRef` sub-fields `conversionStrategy: Default`, `decodingStrategy: None`, `metadataPolicy: None`, `nullBytePolicy: Ignore`.

Follow the same file/definition pattern as `common/templates/_ingressroute.tpl` and (once built) `_toleration.tpl`.

**Blocked by:** None — can start immediately (independent of ticket 02)

**Status:** ready-for-agent

- [ ] Given equivalent inputs, `common.externalSecret`'s output matches `service`'s current `externalsecret.yaml` output byte-for-byte (metadata name, `refreshInterval`, `secretStoreRef`, `target`, and one `data[]` entry per `secretEnv` item)
- [ ] `secretEnv` with multiple entries renders one `data[]` entry per item, each with its own `secretKey`/`property`
- [ ] `enabled: false` (or `remoteKey` unset) renders nothing
- [ ] `kubernetes-v2/charts/common/Chart.yaml`'s version is bumped (this is an addition to an existing chart's public template surface)
