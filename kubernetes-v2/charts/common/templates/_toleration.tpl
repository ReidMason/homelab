{{/*
common.toleration renders the standard node.kubernetes.io/unreachable NoExecute
pod toleration block duplicated across most charts in this repo. Call with a dict:
  tolerationSeconds: int, optional, defaults to 10
*/}}
{{- define "common.toleration" -}}
{{- $seconds := .tolerationSeconds -}}
{{- if kindIs "invalid" $seconds -}}
{{- $seconds = 10 -}}
{{- end -}}
- key: node.kubernetes.io/unreachable
  effect: NoExecute
  tolerationSeconds: {{ $seconds }}
{{- end -}}
