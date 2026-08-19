# 04 — Probes + secretEnv support

**What to build:** `service` supports two more opt-in blocks on the main container:

- `probes.{enabled, path}` — when enabled, renders both a readinessProbe and a livenessProbe as `httpGet` against `containerPort` and `probes.path`, using the delay/period/timeout defaults from the current `seerr` chart (readiness: 60s initial / 15s period / 3s timeout; liveness: 20s initial / 15s period / 3s timeout).
- `secretEnv[]` — a list of `{envName, secretKey}` pairs, each rendered as an env var sourced via `secretKeyRef` against one `externalSecret.name` value (single `ExternalSecret` per app, matching the existing `homelab.externalSecret.name` convention used by `discord-bot`/`cloudflare-ddns`/`sonarr` etc).

**Blocked by:** 2 — Storage support (both edit the main container spec in the Deployment; sequenced to avoid rework/merge conflicts)

**Status:** ready-for-agent

- [ ] `probes.enabled: true` renders readiness + liveness `httpGet` probes against `containerPort`/`probes.path` with the specified default timing
- [ ] `probes.enabled: false` (default) renders no probes
- [ ] `secretEnv` list renders one env var per entry, each sourced via `secretKeyRef` against `externalSecret.name` and the entry's `secretKey`
- [ ] Empty/unset `secretEnv` renders no extra env vars
- [ ] Rendering tests cover: probes enabled/disabled, secretEnv with multiple entries, secretEnv empty
