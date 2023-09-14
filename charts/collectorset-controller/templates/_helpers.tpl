{{/* vim: set filetype=mustache: */}}

{{/*
Common labels
*/}}
{{- define "collectorset-controller.labels" -}}
{{ include "lmutil.generic.labels" . }}
app.kubernetes.io/component: custom-resource-controller
{{/*
Adding app property to make it backward compatible in trasition phase.
New datasources or existing datasources should use app.kubernetes.io/name property in its appliesto script
*/}}
app: collectorset-controller
{{ include "lmutil.selectorLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}


{{/*
Common Annotations
*/}}
{{- define "collectorset-controller.annotations" -}}
logicmonitor.com/provider: lm-container
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "collectorset-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lmutil.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "csc-image" -}}
{{- $registry := "" -}}
{{- $repo := "logicmonitor" -}}
{{- if .Values.image.registry -}}
{{- $registry = .Values.image.registry -}}
{{- else if .Values.global.image.registry -}}
{{- $registry = .Values.global.image.registry -}}
{{- end -}}
{{- if .Values.image.repository -}}
{{- $repo = .Values.image.repository -}}
{{- else if .Values.global.image.repository -}}
{{- $repo = .Values.global.image.repository -}}
{{- end -}}
{{- if ne $registry "" -}}
"{{ $registry }}/{{ $repo }}/{{ .Values.image.name }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- else -}}
"{{ $repo }}/{{ .Values.image.name }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- end -}}
{{- end -}}

{{/*
LM Credentials and Proxy Details.
The user can provide proxy details in values.yaml or by creating user defined secret.
Argus proxy takes precendence over the global proxy. We need to check if the user defined secret contains
Argus proxy details or not, for this we're using Lookup function in helm.
*/}}

{{- define "lm-credentials-and-proxy-details" -}}
{{- $secretObj := (lookup "v1" "Secret" .Release.Namespace .Values.global.userDefinedSecret) | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $data := dict "root" . "secretdata" $secretData }}
{{- include "lmutil.validate-user-provided-secret" $data }}
- name: ACCESS_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: accessID
- name: ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: accessKey
- name: ACCOUNT
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: account
{{- if $secretData.etcdDiscoveryToken }}
- name: ETCD_DISCOVERY_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: etcdDiscoveryToken
{{- end }}
{{- if or $secretData.collectorSetControllerProxyUser $secretData.proxyUser .Values.proxy.user .Values.global.proxy.user }}
- name: PROXY_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      {{- if $secretData.collectorSetControllerProxyUser }}
      key: collectorSetControllerProxyUser
      {{- else }}
      key: proxyUser
      {{- end }}
{{- end }}
{{- if or $secretData.collectorSetControllerProxyUser $secretData.proxyPass .Values.proxy.pass .Values.global.proxy.pass }}
- name: PROXY_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      {{- if $secretData.collectorSetControllerProxyUser }}
      key: collectorSetControllerProxyUser
      {{- else }}
      key: proxyPass
      {{- end }}
{{- end }}
{{- end }}