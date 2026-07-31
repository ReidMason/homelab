{{- define "authentik.env" }}
- name: AUTHENTIK_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.homelab.externalSecret.name }}
      key: secret-key
- name: AUTHENTIK_POSTGRESQL__HOST
  value: {{ .Values.postgresql.host | quote }}
- name: AUTHENTIK_POSTGRESQL__PORT
  value: {{ .Values.postgresql.port | quote }}
- name: AUTHENTIK_POSTGRESQL__NAME
  value: {{ .Values.postgresql.name | quote }}
- name: AUTHENTIK_POSTGRESQL__USER
  value: {{ .Values.postgresql.user | quote }}
- name: AUTHENTIK_POSTGRESQL__PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.homelab.externalSecret.name }}
      key: db-password
- name: AUTHENTIK_REDIS__HOST
  value: {{ .Values.redis.host | quote }}
- name: AUTHENTIK_REDIS__PORT
  value: {{ .Values.redis.port | quote }}
- name: AUTHENTIK_BOOTSTRAP_EMAIL
  value: {{ .Values.homelab.bootstrapEmail | quote }}
- name: AUTHENTIK_BOOTSTRAP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.homelab.externalSecret.name }}
      key: bootstrap-password
{{- end }}

{{- define "authentik.volumeMounts" }}
- name: storage
  mountPath: /media
  subPath: media
- name: storage
  mountPath: /templates
  subPath: templates
- name: certs
  mountPath: /certs
{{- end }}

{{- define "authentik.volumes" }}
- name: storage
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: authentik-media
  {{- else }}
  emptyDir: {}
  {{- end }}
- name: certs
  emptyDir: {}
{{- end }}
