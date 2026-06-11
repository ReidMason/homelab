{{- define "homelab.jellyfin.fullname" -}}
{{- default .Release.Name .Values.jellyfin.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "homelab.jellyfin.imageRef" -}}
{{- $repo := .Values.jellyfin.image.repository | default "docker.io/jellyfin/jellyfin" -}}
{{- $tag := .Values.jellyfin.image.tag | default .Subcharts.jellyfin.Chart.AppVersion -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{- define "homelab.abyss.brandingXml" -}}
<?xml version="1.0" encoding="utf-8"?>
<BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LoginDisclaimer />
  <CustomCss>{{ .Values.homelab.abyss.customCss | trim }}</CustomCss>
  <SplashscreenEnabled>false</SplashscreenEnabled>
  <SplashscreenLocation />
</BrandingOptions>
{{- end -}}

{{- define "homelab.abyss.volumes" -}}
- name: jellyfin-web
  emptyDir: {}
- name: abyss-branding
  configMap:
    name: {{ include "homelab.jellyfin.fullname" . }}-abyss-branding
- name: abyss-spotlight-script
  configMap:
    name: {{ include "homelab.jellyfin.fullname" . }}-abyss-spotlight
    defaultMode: 0555
{{- end -}}

{{- define "homelab.abyss.volumeMounts" -}}
- name: jellyfin-web
  mountPath: /jellyfin/jellyfin-web
{{- end -}}

{{- define "homelab.abyss.initContainers" -}}
- name: abyss-web-copy
  image: {{ include "homelab.jellyfin.imageRef" . }}
  imagePullPolicy: {{ .Values.jellyfin.image.pullPolicy | default "IfNotPresent" }}
  command: ["/bin/sh", "-c"]
  args:
    - cp -a /jellyfin/jellyfin-web/. /web-out/
  volumeMounts:
    - name: jellyfin-web
      mountPath: /web-out
- name: abyss-spotlight
  image: curlimages/curl:8.11.1
  command: ["/scripts/apply-spotlight.sh"]
  env:
    - name: ABYSS_REPO
      value: {{ .Values.homelab.abyss.repo | quote }}
    - name: ABYSS_BRANCH
      value: {{ .Values.homelab.abyss.branch | quote }}
    - name: WEB_DIR
      value: /web-out
  volumeMounts:
    - name: jellyfin-web
      mountPath: /web-out
    - name: abyss-spotlight-script
      mountPath: /scripts
      readOnly: true
- name: abyss-branding
  image: busybox:1.37
  command: ["/bin/sh", "-c"]
  args:
    - |
      mkdir -p /config/config
      cp /branding/branding.xml /config/config/branding.xml
  volumeMounts:
    - name: config
      mountPath: /config
    - name: abyss-branding
      mountPath: /branding
      readOnly: true
{{- end -}}
