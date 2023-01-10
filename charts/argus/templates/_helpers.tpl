{{/* vim: set filetype=mustache: */}}

{{/*
Common labels
*/}}
{{- define "argus.labels" -}}
{{ include "lmutil.generic.labels" . }}
app.kubernetes.io/component: discovery-agent
{{/*
Adding app property to make it backward compatible in trasition phase.
New datasources or existing datasources should use app.kubernetes.io/name property in its appliesto script
*/}}
app: argus
{{ include "lmutil.selectorLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
Common Annotations
*/}}
{{- define "argus.annotations" -}}
logicmonitor.com/provider: lm-container
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end }}



{{- define "cluster.extraprops" }}
{{- range $item := .Values.lm.resourceGroup.extraProps.cluster }}
- {{ toYaml $item | nindent 2 }}
{{- end }}
- name: "kubernetes.resourcedeleteafterduration"
  value: {{ .Values.lm.resource.globalDeleteAfterDuration | quote }}
- name: "lmlogs.k8sevent.enable"
  value: {{ .Values.lm.lmlogs.k8sevent.enable | quote }}
- name: "lmlogs.k8spodlog.enable"
  value: {{ .Values.lm.lmlogs.k8spodlog.enable | quote }}
{{- end }}


{{- define "monitoring.disable" }}
{{ $alwaysDisable := list "ingresses"}}
{{ $resultList := ( concat $alwaysDisable $.Values.monitoring.disable | uniq )  }}
{{- toYaml $resultList | nindent 0}}
{{- end }}

{{- define "alerting.disable" }}
{{ $alwaysDisable := list }}
{{ $resultList := (concat $alwaysDisable $.Values.lm.resource.alerting.disable | uniq )  }}
{{- toYaml $resultList | nindent 0}}
{{- end }}


{{- define "collector.default.labels" }}

{{- end }}

{{- define "collector.labels" }}
{{ $default := dict }}
{{ $_ := set $default "app.kubernetes.io/part-of" (include "lmutil.name" .)}}
{{- $result := (merge $default .Values.collector.labels)}}
{{- toYaml $result | nindent 0 }}
{{/*
Adding app property to make it backward compatible in trasition phase.
New datasources or existing datasources should use app.kubernetes.io/name property in its appliesto script
*/}}
app: collector
{{- end }}


{{- define "argus-image" -}}
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


{{- define "collector-image" -}}
{{- $repo := "logicmonitor" -}}
{{- if .Values.collector.image.repository -}}
{{- $repo = .Values.collector.image.repository -}}
{{- else if .Values.global.image.repository -}}
{{- $repo = .Values.global.image.repository -}}
{{- end -}}
"{{ $repo }}/{{ .Values.collector.image.name }}"
{{- end -}}


{{/*
Collector Pod security context
*/}}
{{- define "collector-psp" }}
{{ toYaml .Values.collector.podSecurityContext | nindent 0 }}
{{- end }}

{{- define "collector-csp" }}
{{- $addCaps := .Values.collector.securityContext.capabilities.add }}
{{- if and (eq (include "lmutil.get-platform" .) "gke") (not (has "NET_RAW" $addCaps)) }}
{{- $addCaps = append $addCaps "NET_RAW" }}
{{- end }}
{{- with .Values.collector.securityContext }}
{{- if not (hasKey . "capabilities") }}
{{ toYaml . | nindent 0 }}
{{- end }}
{{- end }}
capabilities:
  drop: {{ toYaml .Values.collector.securityContext.capabilities.drop | nindent 4 }}
  add: {{ toYaml $addCaps | nindent 4 }}
{{- end }}