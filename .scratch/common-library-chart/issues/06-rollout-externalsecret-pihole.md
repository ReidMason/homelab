# 06 — Roll out common.externalSecret to pihole

**What to build:** `pihole`'s `templates/externalsecret.yaml` (1 `data[]` entry under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`. `Chart.yaml` declares `common` as a `file://../common` dependency (`pihole` already depends on `common` for its toleration fragment — add `externalSecret` usage alongside it, no new dependency block needed if already pinned to a matching version).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
