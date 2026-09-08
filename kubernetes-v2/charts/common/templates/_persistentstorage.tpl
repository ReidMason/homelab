{{/*
common.persistentStorage renders the PVC/PV shapes duplicated across ~10 charts'
templates/pvc.yaml. Call with a dict:
  pvcName: PVC metadata name (also used as the PV's app.kubernetes.io/instance label value)
  pvName: PV metadata name (required only for the NFS PV+PVC shape; not derived from pvcName)
  size: storage request/capacity, e.g. "5Gi"
  storageClass: storage class name (optional) - when set, renders a plain ReadWriteOnce PVC only
  nfs: dict with server/path (optional) - when storageClass is unset and both nfs.server and
    nfs.path are set, renders a ReadWriteMany NFS PersistentVolume paired with a PVC bound to it
    via volumeName. When neither storageClass nor nfs.server/nfs.path are set, renders nothing.

storageClassName is always quoted, matching most existing plain-PVC callers (qbittorrent,
homeassistant, matter-server, radarr, sonarr) and preserving `""`'s "no dynamic provisioner"
meaning. nats/postgres currently emit it unquoted; adopting this fragment changes their
rendered bytes (not their semantics, since their values are non-empty strings) - expected, not
a bug, when their rollout issues land.
*/}}
{{- define "common.persistentStorage" -}}
{{- if .storageClass }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .pvcName }}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: {{ .storageClass | quote }}
  resources:
    requests:
      storage: {{ .size }}
{{- else if and .nfs .nfs.server .nfs.path }}
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ .pvName }}
  labels:
    app.kubernetes.io/instance: {{ .pvcName }}
spec:
  capacity:
    storage: {{ .size }}
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: {{ .nfs.server | quote }}
    path: {{ .nfs.path | quote }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .pvcName }}
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: {{ .size }}
  volumeName: {{ .pvName }}
{{- end }}
{{- end -}}
