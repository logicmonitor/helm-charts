{{/*
Expand the name of the chart.
*/}}
{{- define "fluentd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fluentd.fullname" -}}
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
Adding validations for clustername for lm-logs to contain only lower alphanumeric or '-' and start and end with an alphanumeric character
*/}}
{{- define "kubernetes.cluster_name" -}}
{{- $cluster := "" -}}
{{- if .Values.kubernetes.cluster_name -}}
{{- $cluster = .Values.kubernetes.cluster_name -}}
{{- else if .Values.global.clusterName -}}
{{- $cluster = .Values.global.clusterName -}}
{{- end -}}
{{- if ne $cluster "" -}}
{{- if regexMatch "^[a-z0-9][a-z0-9-]*[a-z0-9]$" $cluster }}
kubernetes.cluster_name {{ $cluster }}
{{- else -}}
{{- fail "cluster_name should contain only lower alphanumeric or '-' and should start and end with an alphanumeric character" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
User-agent for log-ingest requests */}}
{{- define "logsource.userAgent" -}}
{{- $cluster := "" -}}
{{- if .Values.kubernetes.cluster_name -}}
{{- $cluster = .Values.kubernetes.cluster_name -}}
{{- else if .Values.global.clusterName -}}
{{- $cluster = .Values.global.clusterName -}}
{{- end -}}
log_source lm-logs-fluentd (K8S; {{ $cluster }})
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fluentd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fluentd.labels" -}}
helm.sh/chart: {{ include "fluentd.chart" . }}
app.kubernetes.io/component: lm-logs-agent
app.kubernetes.io/part-of: {{ template "fluentd.name" . }}
{{ include "fluentd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fluentd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fluentd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common Annotations
*/}}
{{- define "fluentd.annotations" -}}
logicmonitor.com/provider: lm-container
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "fluentd.serviceAccountName" -}}
{{- default (include "fluentd.fullname" .)}}
{{- end }}

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

{{- define "ds-env" -}}
{{- $envList := list  -}}
{{- range $key, $val := .Values.env -}}
{{- $envProps := dict -}}
{{- $_ := set $envProps "name" $key -}}
{{- $_ = set $envProps "value" ($val) -}}
{{- $envList = append $envList $envProps -}}
{{- end -}}
{{- toYaml $envList | nindent 0 -}}
{{- end -}}

{{- define "fluentd-image" -}}
"{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- end -}}

{{- define "fluentd.lmMatch" -}}
<match {{ .tag }}>
  @type lm
  company_name {{ if .context.Values.lm_company_name }}{{ .context.Values.lm_company_name }}{{ else }}{{ required "A valid .Values.lm_company_name or .Values.global.account entry is required!" .context.Values.global.account }}{{ end }}
  company_domain {{ .context.Values.lm_company_domain | default .context.Values.global.companyDomain | default "logicmonitor.com" }}
  resource_mapping '{{ .resource_mapping }}'
  resource_type {{ .context.Values.fluent.resource_type | default "" }}
  {{- if and (or .context.Values.lm_access_id .context.Values.global.accessID) (or .context.Values.lm_access_key .context.Values.global.accessKey) }}
  access_id {{ .context.Values.lm_access_id | default .context.Values.global.accessID }}
  access_key {{ .context.Values.lm_access_key | default .context.Values.global.accessKey }}
  {{- else if .context.Values.lm_bearer_token }}
  bearer_token {{ .context.Values.lm_bearer_token }}
  {{- else }}
  {{ required "Either specify valid lm_access_id and lm_access_key both or lm_bearer_token for authentication with LogicMonitor." .context.Values.lm_bearer_token }}
  {{- end }}
  debug false
  compression gzip
  {{ include "logsource.userAgent" .context | nindent 8 }}
  include_metadata {{ hasKey .context.Values.fluent "include_metadata" | ternary .context.Values.fluent.include_metadata true }}
  device_less_logs {{ .context.Values.fluent.device_less_logs | default false }}
  <buffer>
    @type memory
    flush_interval {{ .context.Values.fluent.buffer.memory.flush_interval | default "1s" }}
    chunk_limit_size {{ .context.Values.fluent.buffer.memory.chunk_limit_size | default "8m" }}
    flush_thread_count {{ .context.Values.fluent.buffer.memory.flush_thread_count | default "8" }}
  </buffer>
</match>
{{- end }}

{{/*
Optional systemd.conf block for ConfigMap rendering (with context passing)
*/}}
{{- define "fluentd.systemdConfBlock" -}}
{{- $ctx := .context -}}
{{- if $ctx.Values.useSystemdConf }}
  {{- if not $ctx.Values.systemd.conf }}
systemd.conf: |
  <source>
    @type systemd
    path /run/log/journal
    tag systemd.al2023
    read_from_head false
    <storage>
      @type local
      persistent false
    </storage>
  </source>

  <match systemd.al2023>
    @type relabel
    @label @PROCESS_AFTER_CONCAT
  </match>
  {{- else }}
systemd.conf: |
{{ $ctx.Values.systemd.conf | indent 2 }}
  {{- end }}
{{- else }}
systemd.conf: ""
{{- end }}
{{- end }}