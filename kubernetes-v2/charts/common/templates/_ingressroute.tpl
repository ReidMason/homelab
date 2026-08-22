{{/*
common.ingressRoute renders a Traefik IngressRoute matching the shape shared by
~20 charts in this repo (host, entryPoints, optional middleware, optional
Authentik forwardAuth). Call with a dict:
  name: metadata name / target Service name
  ingressRoute: the values block, shaped like:
    enabled: bool
    host: string
    entryPoints: []string
    servicePort: int
    middleware: {enabled, name, namespace}
    forwardAuth: {enabled, middlewareName, middlewareNamespace, outpostServiceName, outpostServiceNamespace, outpostServicePort}
*/}}
{{- define "common.ingressRoute" -}}
{{- if and .ingressRoute.enabled .ingressRoute.host }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ .name }}
spec:
  entryPoints:
{{- range .ingressRoute.entryPoints }}
    - {{ . }}
{{- end }}
  routes:
    {{- if .ingressRoute.forwardAuth.enabled }}
    - match: Host(`{{ .ingressRoute.host }}`) && PathPrefix(`/outpost.goauthentik.io/`)
      kind: Rule
      priority: 15
      services:
        - name: {{ .ingressRoute.forwardAuth.outpostServiceName }}
          namespace: {{ .ingressRoute.forwardAuth.outpostServiceNamespace }}
          port: {{ .ingressRoute.forwardAuth.outpostServicePort }}
    {{- end }}
    - match: Host(`{{ .ingressRoute.host }}`)
      kind: Rule
      services:
        - name: {{ .name }}
          port: {{ .ingressRoute.servicePort }}
      {{- if or .ingressRoute.middleware.enabled .ingressRoute.forwardAuth.enabled }}
      middlewares:
        {{- if .ingressRoute.middleware.enabled }}
        - name: {{ .ingressRoute.middleware.name }}
          namespace: {{ .ingressRoute.middleware.namespace }}
        {{- end }}
        {{- if .ingressRoute.forwardAuth.enabled }}
        - name: {{ .ingressRoute.forwardAuth.middlewareName }}
          namespace: {{ .ingressRoute.forwardAuth.middlewareNamespace }}
        {{- end }}
      {{- end }}
{{- end }}
{{- end -}}
