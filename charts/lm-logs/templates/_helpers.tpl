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
Did the user set global.userDefinedSecret?
*/}}
{{- define "lm-logs.userSecretSet" -}}
{{- if .Values.global.userDefinedSecret }}true{{ end -}}
{{- end -}}

{{/*
Return the credentials Secret name:
- If global.userDefinedSecret is provided, use that.
- Otherwise fall back to <fullname>-creds.
*/}}
{{- define "lm-logs.credsSecretName" -}}
{{- if .Values.global.userDefinedSecret -}}
{{- .Values.global.userDefinedSecret -}}
{{- else -}}
{{- printf "%s-creds" (include "fluentd.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* True if we have any creds in any source (used by template fail-guard) */}}
{{- define "lm-logs.credsProvided" -}}
{{- $uds := default "" .Values.global.userDefinedSecret -}}
{{- $ga := default "" .Values.global.accessID -}}
{{- $gk := default "" .Values.global.accessKey -}}
{{- $va := default "" .Values.lm_access_id -}}
{{- $vk := default "" .Values.lm_access_key -}}
{{- $vb := default "" .Values.lm_bearer_token -}}
{{- if or (ne $uds "")
          (and (ne $ga "") (ne $gk ""))
          (and (ne $va "") (ne $vk ""))
          (ne $vb "") -}}true{{- end -}}
{{- end -}}

{{/*
Emit a secretKeyRef block given a key name.
Usage:
  {{ include "lm-logs.secretKeyRef" (dict "ctx" . "key" "bearerToken") | nindent 10 }}
*/}}
{{- define "lm-logs.secretKeyRef" -}}
name: {{ include "lm-logs.credsSecretName" .ctx }}
key: {{ .key }}
optional: true
{{- end -}}

{{/* Validate credentials + account at render time */}}
{{- define "lm-logs.assertInputs" -}}
{{- $ns := .Release.Namespace -}}
{{- $mode := default "" .Values.authMode -}}
{{- $uds  := default "" .Values.global.userDefinedSecret -}}

{{- /* Fetch Secret if configured */ -}}
{{- $sec := dict -}}
{{- if ne $uds "" -}}
  {{- $sec = lookup "v1" "Secret" $ns $uds | default dict -}}
  {{- if not $sec }}
    {{- fail (printf "global.userDefinedSecret=%q not found in namespace %q" $uds $ns) -}}
  {{- end -}}
{{- end -}}

{{- /* Helper: what keys exist in Secret? */ -}}
{{- $hasSecKey := (and (ne $uds "")
                        $sec.data
                        (kindIs "map" $sec.data)) -}}
{{- $secHas := dict -}}
{{- if $hasSecKey -}}
  {{- $_ := set $secHas "account"     (hasKey $sec.data "account") -}}
  {{- $_ := set $secHas "accessID"    (hasKey $sec.data "accessID") -}}
  {{- $_ := set $secHas "accessKey"   (hasKey $sec.data "accessKey") -}}
  {{- $_ := set $secHas "bearerToken" (hasKey $sec.data "bearerToken") -}}
{{- end -}}

{{- /* 1) Enforce account name presence (values OR global OR Secret) */ -}}
{{- $hasAccount := or
      (ne (default "" .Values.lm_company_name) "")
      (ne (default "" .Values.global.account) "")
      (and (ne $uds "") ($secHas.account | default false)) -}}
{{- if not $hasAccount -}}
  {{- fail "Account name missing: set lm_company_name or global.account, or provide Secret with key 'account' via global.userDefinedSecret." -}}
{{- end -}}

{{- /* 2) Enforce credentials per authMode */ -}}
{{- if eq $mode "lmv1" -}}
  {{- $haslmv1FromSecret := and (ne $uds "") ($secHas.accessID | default false) ($secHas.accessKey | default false) -}}
  {{- $haslmv1FromGlobal := and (ne (default "" .Values.global.accessID) "")
                                (ne (default "" .Values.global.accessKey) "") -}}
  {{- $haslmv1FromValues := and (ne (default "" .Values.lm_access_id) "")
                                (ne (default "" .Values.lm_access_key) "") -}}
  {{- if not (or $haslmv1FromSecret $haslmv1FromGlobal $haslmv1FromValues) -}}
    {{- fail "LM v1 auth selected (authMode=lmv1) but no lmv1 found. Provide either: Secret with 'accessID'+'accessKey', or global.accessID+global.accessKey, or lm_access_id+lm_access_key." -}}
  {{- end -}}

{{- else if eq $mode "bearer" -}}
  {{- $hasBearerFromSecret := and (ne $uds "") ($secHas.bearerToken | default false) -}}
  {{- $hasBearerFromValues := ne (default "" .Values.lm_bearer_token) "" -}}
  {{- if not (or $hasBearerFromSecret $hasBearerFromValues) -}}
    {{- fail "Bearer auth selected (authMode=bearer) but no token found. Provide either: Secret with 'bearerToken' or lm_bearer_token in values." -}}
  {{- end -}}

{{- else -}}
  {{- fail "authMode must be 'lmv1' or 'bearer'." -}}
{{- end -}}
{{- end -}}

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
User-agent for log-ingest requests
*/}}
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

{{/*
Emit auth lines. If .Values.authMode is set, honor it; else use auto priority.
Auto priority: Secret(lmv1) → global lmv1 → values lmv1 → values bearer
*/}}
{{- define "lm-logs.authBlock" -}}
{{- $mode := default "" .Values.authMode -}}
{{- $uds := default "" .Values.global.userDefinedSecret -}}
{{- $ga := default "" .Values.global.accessID -}}
{{- $gk := default "" .Values.global.accessKey -}}
{{- $va := default "" .Values.lm_access_id -}}
{{- $vk := default "" .Values.lm_access_key -}}
{{- $vb := default "" .Values.lm_bearer_token -}}

{{- if eq $mode "lmv1" -}}
  {{- if ne $uds "" -}}
access_id "#{ENV['LM_ACCESS_ID']}"
access_key "#{ENV['LM_ACCESS_KEY']}"
  {{- else if and (ne $ga "") (ne $gk "") -}}
access_id {{ $ga | quote }}
access_key {{ $gk | quote }}
  {{- else if and (ne $va "") (ne $vk "") -}}
access_id {{ $va | quote }}
access_key {{ $vk | quote }}
  {{- end -}}

{{- else if eq $mode "bearer" -}}
  {{- if ne $uds "" -}}
bearer_token "#{ENV['LM_BEARER_TOKEN']}"
  {{- else if ne $vb "" -}}
bearer_token {{ $vb | quote }}
  {{- end -}}

{{- else -}}
  {{- if ne $uds "" -}}
access_id "#{ENV['LM_ACCESS_ID']}"
access_key "#{ENV['LM_ACCESS_KEY']}"
  {{- else if and (ne $ga "") (ne $gk "") -}}
access_id {{ $ga | quote }}
access_key {{ $gk | quote }}
  {{- else if and (ne $va "") (ne $vk "") -}}
access_id {{ $va | quote }}
access_key {{ $vk | quote }}
  {{- else if ne $vb "" -}}
bearer_token {{ $vb | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Fluentd <match> block with company_name priority:
ENV['LM_ACCOUNT'] → global.account → lm_company_name
*/}}
{{- define "fluentd.lmMatch" -}}
<match {{ .tag }}>
  @type lm
  {{ $fb := .context.Values.global.account | default .context.Values.lm_company_name | default "" }}
  company_name "#{ENV['LM_ACCOUNT'].to_s != '' ? ENV['LM_ACCOUNT'] : '{{ $fb }}'}"
  company_domain {{ .context.Values.lm_company_domain | default .context.Values.global.companyDomain | default "logicmonitor.com" }}
  resource_mapping '{{ .resource_mapping }}'
  resource_type {{ .context.Values.fluent.resource_type | default "k8s" }}
{{ include "lm-logs.authBlock" .context | nindent 2 }}

  debug false
  compression gzip
  {{ include "logsource.userAgent" .context }}
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

