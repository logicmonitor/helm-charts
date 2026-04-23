{{/* vim: set filetype=mustache: */}}

{{/*
Common labels
*/}}
{{- define "argus.labels" -}}
{{ include "lmutil.generic.labels" . }}
app.kubernetes.io/component: discovery-agent
{{/*
The following label sets the monitoring mode for Argus resources:
- If this is an upgrade scenario and .Values.monitoringMode is empty, use "Advanced".
- If .Values.monitoringMode is set, use its value. Otherwise, default to "Essentials".
*/}}
{{- if or (has .Values.monitoringMode (list "Minimal" "Essentials" "Essential")) (and (eq .Values.monitoringMode "") (not (.Release.IsUpgrade))) }}
argus.monitoring-mode: "Essentials"
{{- else }}
argus.monitoring-mode: "Advanced"
{{- end}}
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
{{ $alwaysDisable := list }}
{{- if or (has .Values.monitoringMode (list "Minimal" "Essentials" "Essential")) (and (eq .Values.monitoringMode "") (not (.Release.IsUpgrade))) }}
{{ $alwaysDisable = list "resourcequotas" "limitranges" "roles" "rolebindings" "networkpolicies" "configmaps" "clusterrolebindings" "clusterroles" "priorityclasses" "storageclasses" "cronjobs" "jobs" "endpoints" "ingresses" "secrets" "serviceaccounts" "poddisruptionbudgets" "customresourcedefinitions" }}
{{- end }}

{{ $resultList := ( concat $alwaysDisable $.Values.monitoring.disable | uniq )  }}
{{- toYaml $resultList | nindent 0}}
{{- end }}

{{- define "monitoring.annotations.ignore" }}
{{ $alwaysIgnore := list "key in ('virtual-kubelet.io/last-applied-node-status', 'control-plane.alpha.kubernetes.io/leader','autoscaling.alpha.kubernetes.io/current-metrics','autoscaling.alpha.kubernetes.io/conditions')" "key =~ 'last-applied'"}}
{{ $resultList := ( concat $alwaysIgnore $.Values.monitoring.annotations.ignore | uniq )  }}
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

{{- define "ksm-url" -}}
{{- $url := "" }}
{{- $ksm := index .Values.global "kube-state-metrics" }}
{{- if not (empty .Values.ksmUrl) }}
{{- $url = .Values.ksmUrl }}
{{- else if $ksm.enabled }}
{{- $port := 8080 }}
{{- $url = printf "http://%s-kube-state-metrics.%s.svc.cluster.local:%d/metrics" .Release.Name .Release.Namespace $port }}
{{- end }}
{{- $url }}
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

{{/*
LM Credentials and Proxy Details.

These env vars are emitted statically into the Deployment so the manifest is
fully declarative and GitOps tools (Rancher Fleet, Argo CD) do not see drift.
This replaces a post-install Job that previously patched the Deployment env
based on a runtime lookup of the user-defined Secret.

Precedence enforced by the Argus binary (see pkg/config/config.go,
applySecretEnvOverrides): values from the user-defined Secret win over the
plaintext values rendered from .Values. Every `*_FROM_SECRET` env var uses
`optional: true` so a key missing from the user-defined Secret simply leaves
the override unset — Argus then falls back to the plaintext env.
*/}}

{{- define "argus.lm-credentials-and-proxy-details" -}}
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
{{- /* COMPANY_DOMAIN: secret override (if userDefinedSecret) wins, else plaintext */}}
{{- if .Values.global.userDefinedSecret }}
- name: COMPANY_DOMAIN_FROM_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: companyDomain
      optional: true
{{- end }}
- name: COMPANY_DOMAIN
  value: {{ .Values.global.companyDomain | default "logicmonitor.com" | quote }}
{{- /* ETCD_DISCOVERY_TOKEN: optional, sourced from secret only */}}
{{- if .Values.global.userDefinedSecret }}
- name: ETCD_DISCOVERY_TOKEN_FROM_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: etcdDiscoveryToken
      optional: true
{{- else }}
- name: ETCD_DISCOVERY_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: etcdDiscoveryToken
      optional: true
{{- end }}
{{- /* PROXY_USER: argus-specific secret key wins over generic, then plaintext */}}
{{- if .Values.global.userDefinedSecret }}
- name: PROXY_USER_FROM_SECRET_ARGUS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: argusProxyUser
      optional: true
- name: PROXY_USER_FROM_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: proxyUser
      optional: true
{{- else if or .Values.proxy.user .Values.global.proxy.user }}
- name: PROXY_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: proxyUser
{{- end }}
{{- /* PROXY_PASS: argus-specific secret key wins over generic, then plaintext */}}
{{- if .Values.global.userDefinedSecret }}
- name: PROXY_PASS_FROM_SECRET_ARGUS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: argusProxyPass
      optional: true
- name: PROXY_PASS_FROM_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: proxyPass
      optional: true
{{- else if or .Values.proxy.pass .Values.global.proxy.pass }}
- name: PROXY_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: proxyPass
{{- end }}
{{- end }}
