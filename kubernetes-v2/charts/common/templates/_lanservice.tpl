{{/*
common.lanService renders the MetalLB LoadBalancer Service duplicated across
~5 charts' templates/service.yaml, alongside each chart's primary ClusterIP
Service. Call with a dict:
  name: base app name - rendered Service is named "<name>-lan"; selector is "app: <name>"
  metallbAddressPool: optional metallb.io/address-pool annotation value, defaults to
    "default-pool" (the cluster's only MetalLB pool)
  type: spec.type
  loadBalancerIP: optional spec.loadBalancerIP
  ports: caller-supplied list of {name, port, targetPort} - not derived from any other
    resource, since e.g. qbittorrent-lan intentionally omits the primary Service's
    flaresolverr port

The lanService.enabled guard is the caller's responsibility, wrapping the include call.
*/}}
{{- define "common.lanService" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}-lan
  annotations:
    metallb.io/address-pool: {{ .metallbAddressPool | default "default-pool" | quote }}
spec:
  type: {{ .type }}
  {{- if .loadBalancerIP }}
  loadBalancerIP: {{ .loadBalancerIP | quote }}
  {{- end }}
  selector:
    app: {{ .name }}
  ports:
    {{- range .ports }}
    - name: {{ .name }}
      protocol: TCP
      port: {{ .port }}
      targetPort: {{ .targetPort }}
    {{- end }}
{{- end -}}
