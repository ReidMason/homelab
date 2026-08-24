# 05 — Roll out common.externalSecret to kube-prometheus-stack

**What to build:** `kube-prometheus-stack` has two inline ExternalSecrets — `templates/externalsecret.yaml` (admin-user/admin-password, under `.Values.homelab.externalSecret`) and `templates/alertmanager-externalsecret.yaml` (single secretKey/property pair, under `.Values.homelab.alertmanager.externalSecret`) — both replaced with calls to `common.externalSecret`. `Chart.yaml` declares `common` as a `file://../common` dependency.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `kube-prometheus-stack/Chart.yaml` depends on `common`, version pin matches `common/Chart.yaml`'s current version
- [ ] `templates/externalsecret.yaml` and `templates/alertmanager-externalsecret.yaml` both call `common.externalSecret`
- [ ] `helm template` output for both resources is byte-identical to the pre-migration output for equivalent values
- [ ] No vendored `charts/*.tgz`/`Chart.lock` committed
