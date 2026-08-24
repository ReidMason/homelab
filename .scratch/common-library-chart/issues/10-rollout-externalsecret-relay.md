# 10 — Roll out common.externalSecret to relay (notifier)

**What to build:** `relay`'s `templates/notifier-externalsecret.yaml` (1 `data[]` entry, values nested under `.Values.notifier.homelab.externalSecret` rather than the flat `.Values.homelab.externalSecret` most other charts use) is replaced with a call to `common.externalSecret`, passing the nested values block through to the fragment's dict signature. `relay` already depends on `common` for its toleration fragment — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/notifier-externalsecret.yaml` calls `common.externalSecret`, correctly sourcing from `.Values.notifier.homelab.externalSecret`
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
