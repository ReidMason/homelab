# 08 — Roll out common.externalSecret to qbittorrent

**What to build:** `qbittorrent`'s `templates/externalsecret.yaml` (2 `data[]` entries: VPN user/password, under `.Values.homelab.externalSecret`) is replaced with a call to `common.externalSecret`. `qbittorrent` already depends on `common` for its toleration fragment — reuse that dependency block.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `templates/externalsecret.yaml` calls `common.externalSecret` instead of hand-rendering the resource
- [ ] `helm template` output is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
