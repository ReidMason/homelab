{{/*
common.externalSecret renders an ExternalSecret matching the shape duplicated
across ~15 charts in this repo. Call with a dict:
  name: metadata name / target Secret name
  remoteKey: remote key in the secret store
  refreshInterval: string
  clusterSecretStoreName: string
  secretEnv: list of {secretKey, property}
  enabled: bool
*/}}
{{- define "common.externalSecret" -}}
{{- if and .enabled .remoteKey }}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ .name | quote }}
spec:
  refreshInterval: {{ .refreshInterval | quote }}
  secretStoreRef:
    name: {{ .clusterSecretStoreName | quote }}
    kind: ClusterSecretStore
  target:
    name: {{ .name | quote }}
    creationPolicy: Owner
    deletionPolicy: Retain
  data:
    {{- range .secretEnv }}
    - secretKey: {{ .secretKey | quote }}
      remoteRef:
        key: {{ $.remoteKey | quote }}
        property: {{ .property | quote }}
        conversionStrategy: Default
        decodingStrategy: None
        metadataPolicy: None
        nullBytePolicy: Ignore
    {{- end }}
{{- end }}
{{- end -}}
