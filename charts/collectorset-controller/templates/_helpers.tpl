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