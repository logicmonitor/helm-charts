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
{{ $alwaysDisable := list }}
{{- if and (not .Release.IsUpgrade) (has .Values.monitoringMode (list "Minimal" "Essentials" "Essential")) }}
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
{{- else }}
{{- $nsservices := (lookup "v1" "Service" .Release.Namespace "") | default dict }}
{{- $nsfilteredServices := dict "items" (list) }}
{{- range $service := $nsservices.items }}
  {{- if eq (index $service.metadata.labels "app.kubernetes.io/name" | default "") "kube-state-metrics" }}
    {{- $_ := set $nsfilteredServices "items" (append $nsfilteredServices.items $service) }}
    {{- $port := "" }}
    {{- range $p := $service.spec.ports }}
      {{- if or (eq $p.name "http") (eq $p.name "http-metrics") }}
        {{- $port = $p.port }}
      {{- end }}
    {{- end }}
    {{- $url = printf "http://%s.%s.svc.cluster.local:%d/metrics" $service.metadata.name $service.metadata.namespace $port }}
  {{- end }}
{{- end }}
{{- if (empty $url)}}
{{- $services := (lookup "v1" "Service" "" "") | default dict }}
{{- $filteredServices := dict "items" (list) }}
{{- range $service := $services.items }}
  {{- if eq (index $service.metadata.labels "app.kubernetes.io/name" | default "") "kube-state-metrics" }}
    {{- $_ := set $filteredServices "items" (append $filteredServices.items $service) }}
    {{- $port := "" }}
    {{- range $p := $service.spec.ports }}
      {{- if or (eq $p.name "http") (eq $p.name "http-metrics") }}
        {{- $port = $p.port }}
      {{- end }}
    {{- end }}
    {{- $url = printf "http://%s.%s.svc.cluster.local:%d/metrics" $service.metadata.name $service.metadata.namespace $port }}
  {{- end }}
{{- end }}
{{- end }}
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
- name: COMPANY_DOMAIN
{{- if and .Values.global.userDefinedSecret (or (not (hasKey $secretData "companyDomain")) (eq (get $secretData "companyDomain") "")) }}
  value: "logicmonitor.com"
{{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: companyDomain
{{- end}}
{{- if $secretData.etcdDiscoveryToken }}
- name: ETCD_DISCOVERY_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      key: etcdDiscoveryToken
{{- end }}
{{- if or $secretData.argusProxyUser $secretData.proxyUser .Values.proxy.user .Values.global.proxy.user }}
- name: PROXY_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      {{- if $secretData.argusProxyUser }}
      key: argusProxyUser
      {{- else }}
      key: proxyUser
      {{- end }}
{{- end }}
{{- if or $secretData.argusProxyPass $secretData.proxyPass .Values.proxy.pass .Values.global.proxy.pass }}
- name: PROXY_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "lmutil.secret-name" . }}
      {{- if $secretData.argusProxyPass }}
      key: argusProxyPass
      {{- else }}
      key: proxyPass
      {{- end }}
{{- end }}
{{- end }}
