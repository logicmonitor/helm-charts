{{- define "lmutil.is-openshift" }}
{{- $is := false }}
{{- range (.Capabilities.APIVersions | toStrings)}}
{{- if contains "openshift.io" . }}
{{- $is = true }}
{{- end }}
{{- end }}
{{- printf "%t" $is }}
{{- end }}


{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "lmutil.rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}


{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "lmutil.release.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}


{{- define "lmutil.get-platform" }}
{{- if contains "-gke" .Capabilities.KubeVersion.Version }}
{{- printf "%s" "gke" }}
{{- else if contains "-eks" .Capabilities.KubeVersion.Version }}
{{- printf "%s" "eks" }}
{{- else if contains "+vmware" .Capabilities.KubeVersion.Version }}
{{- printf "%s" "vmware" }}
{{- else if contains "-rancher" .Capabilities.KubeVersion.Version }}
{{- printf "%s" "rancher" }}
{{- else if contains "-mirantis" .Capabilities.KubeVersion.Version }}
{{- printf "%s" "mirantis" }}
{{- else if eq (include "lmutil.is-openshift" .) "true" }}
{{- printf "%s" "openshift" }}
{{- else }}
{{- printf "%s" "unknown" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lmutil.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "lmutil.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lmutil.fullname" -}}
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

{{ define "lmutil.imagePullSecrets" }}
{{ $result := (concat .Values.imagePullSecrets .Values.global.imagePullSecrets | uniq)}}
{{ toYaml $result | nindent 0 }}
{{ end }}

{{/*
Selector labels
*/}}
{{- define "lmutil.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lmutil.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "lmutil.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lmutil.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "lmutil.generic.labels" }}
helm.sh/chart: {{ template "lmutil.chart" . }}
app.kubernetes.io/part-of: {{ include "lmutil.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}


{{- /*
lmutil.merge will merge two YAML templates and output the result.
This takes an array of three values:
- the top context
- the template name of the overrides (destination)
- the template name of the base (source)
*/}}
{{- define "lmutil.merge" -}}
{{- $top := first . -}}
{{- $overrides := fromYaml (include (index . 1) $top) | default (dict ) -}}
{{- $tpl := fromYaml (include (index . 2) $top) | default (dict ) -}}
{{- toYaml (merge $overrides $tpl) -}}
{{- end -}}

{{- define "lmutil.custom-pod-sec-context-nonroot" }}
{{- toYaml .Values.podSecurityContext | nindent 0 }}
{{- end }}
{{- define "lmutil.pod-sec-context-nonroot" -}}
{{- include "lmutil.merge" (append . "lmutil.default-pod-sec-context-nonroot" ) -}}
{{- end -}}

{{- define "lmutil.custom-container-sec-context-nonroot" }}
{{- toYaml .Values.securityContext | nindent 0 }}
{{- end }}
{{- define "lmutil.container-sec-context-nonroot" -}}
{{- include "lmutil.merge" (append . "lmutil.default-container-sec-context-nonroot" ) -}}
{{- end -}}

{{/*
Return secret name to be used based on the userDefinedSecret.
*/}}
{{- define "lmutil.secret-name" -}}
{{- if .Values.global.userDefinedSecret -}}
{{- .Values.global.userDefinedSecret -}}
{{- else -}}
{{- include "lmutil.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Check if the user provided secret contains mandatory fields i.e.accessID, accessKey and account
*/}}
{{- define "lmutil.validate-user-provided-secret" -}}
{{- if and .root.Values.global.userDefinedSecret (not .secretdata.accessID) }}
{{- required "A valid accessID is required in the provided secret" .secretdata.accessID }}
{{- else if and .root.Values.global.userDefinedSecret (not .secretdata.accessKey) }}
{{- required "A valid accessKey is required in the provided secret" .secretdata.accessKey }}
{{- else if and .root.Values.global.userDefinedSecret (not .secretdata.account) }}
{{- required "A valid account is required in the provided secret" .secretdata.account }}
{{- end }}
{{- end }}