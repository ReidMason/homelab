{{/*
common.namespace renders the Namespace resource duplicated across ~7 charts'
templates/namespace.yaml, with the standard privileged pod-security label
triad. Call with a dict:
  name: metadata name (caller decides how to express it, e.g. .Release.Namespace,
    quoted or not - not preserved byte-for-byte across callers, accepted variance)

Not parameterized beyond name - no current duplicator needs a pod-security level
other than "privileged". Any caller-side conditional (e.g. matter-server's
`if .Values.hostNetwork`) wraps the include call, not the fragment itself.
*/}}
{{- define "common.namespace" -}}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .name }}
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
{{- end -}}
