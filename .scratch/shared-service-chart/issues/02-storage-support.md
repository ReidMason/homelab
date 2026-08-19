# 02 — Storage support (NFS + StorageClass PVC)

**What to build:** `service` supports two alternate, opt-in storage shapes, matching the two patterns already in use across the cluster:

- `storage.nfs.{enabled, server, path, size, claimName}` — renders an NFS-backed PersistentVolume + PersistentVolumeClaim pair (`ReadWriteMany`, `Retain` reclaim policy, PV named `{{ .Release.Namespace }}-<claimName>`), mirroring the current `habit-tracker`/`seerr` pattern.
- `storage.pvc.{enabled, storageClassName, size, claimName}` — renders a plain PersistentVolumeClaim only (no PV) against the given storage class, mirroring the `qbittorrent`-style pattern.
- `storage.mountPath` — where the resulting volume is mounted in the main container, wired into the Deployment from ticket 01.

Only one of `storage.nfs`/`storage.pvc` should be enabled at a time; when neither is enabled, no storage resources render and the Deployment has no extra volume.

**Blocked by:** 1 — Scaffold `service` chart core

**Status:** ready-for-agent

- [ ] `storage.nfs.enabled: true` renders a PV + PVC pair matching the current NFS pattern (RWX, Retain, PV/PVC naming)
- [ ] `storage.pvc.enabled: true` renders a plain PVC against `storage.pvc.storageClassName`, no PV
- [ ] The main container in the Deployment mounts the resulting claim at `storage.mountPath` when either storage block is enabled
- [ ] With both storage blocks disabled (default), no PV/PVC renders and the Deployment has no extra volume
- [ ] Rendering tests cover: NFS enabled, StorageClass PVC enabled, and both disabled
