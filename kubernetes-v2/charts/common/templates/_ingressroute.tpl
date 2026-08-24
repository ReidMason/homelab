{{/*
common.ingressRoute renders a Traefik IngressRoute matching the shape shared by
~20 charts in this repo (host, entryPoints, optional middleware, optional
Authentik forwardAuth). Call with a dict:
  name: metadata name
  serviceName: target Service name for the primary route (optional, defaults to name)
  ingressRoute: the values block, shaped like:
    enabled: bool
    host: string
    entryPoints: []string
    servicePort: int
    scheme: string (optional, emitted on the primary route's service only when set)
    middleware: {enabled, name, namespace} (optional, omit entirely if unused)
    forwardAuth: {enabled, middlewareName, middlewareNamespace, outpostServiceName, outpostServiceNamespace, outpostServicePort} (optional, omit entirely if unused)
*/}}
{{- define "common.ingressRoute" -}}
{{- if and .ingressRoute.enabled .ingressRoute.host }}
{{- $middleware := .ingressRoute.middleware | default dict }}
{{- $forwardAuth := .ingressRoute.forwardAuth | default dict }}
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
    {{- if $forwardAuth.enabled }}
    - match: Host(`{{ .ingressRoute.host }}`) && PathPrefix(`/outpost.goauthentik.io/`)
      kind: Rule
      priority: 15
      services:
        - name: {{ $forwardAuth.outpostServiceName }}
          namespace: {{ $forwardAuth.outpostServiceNamespace }}
          port: {{ $forwardAuth.outpostServicePort }}
    {{- end }}
    - match: Host(`{{ .ingressRoute.host }}`)
      kind: Rule
      services:
        - name: {{ .serviceName | default .name }}
          port: {{ .ingressRoute.servicePort }}
          {{- if .ingressRoute.scheme }}
          scheme: {{ .ingressRoute.scheme }}
          {{- end }}
      {{- if or $middleware.enabled $forwardAuth.enabled }}
      middlewares:
        {{- if $middleware.enabled }}
        - name: {{ $middleware.name }}
          namespace: {{ $middleware.namespace }}
        {{- end }}
        {{- if $forwardAuth.enabled }}
        - name: {{ $forwardAuth.middlewareName }}
          namespace: {{ $forwardAuth.middlewareNamespace }}
        {{- end }}
      {{- end }}
{{- end }}
{{- end -}}
