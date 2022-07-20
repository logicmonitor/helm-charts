{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "argus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argus.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argus.labels" -}}
helm.sh/chart: {{ include "argus.chart" . }}
app.kubernetes.io/component: discovery-agent
app.kubernetes.io/part-of: {{ template "argus.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{/*
Adding app property to make it backward compatible in trasition phase.
New datasources or existing datasources should use app.kubernetes.io/name property in its appliesto script
*/}}
app: argus
{{ include "argus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
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

{{/*
Create the name of the service account to use
*/}}
{{- define "argus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "argus.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}



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
{{ $alwaysDisable := list "secrets" "networkpolicies"}}
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
{{ $_ := set $default "app.kubernetes.io/part-of" (include "argus.name" .)}}
{{- $result := (merge $default .Values.collector.labels)}}
{{- toYaml $result | nindent 0 }}
{{/*
Adding app property to make it backward compatible in trasition phase.
New datasources or existing datasources should use app.kubernetes.io/name property in its appliesto script
*/}}
app: collector
{{- end }}

{{ define "argus.imagePullSecrets" }}
{{ $result := (concat .Values.imagePullSecrets .Values.global.imagePullSecrets | uniq)}}
{{ toYaml $result | nindent 0 }}
{{ end }}