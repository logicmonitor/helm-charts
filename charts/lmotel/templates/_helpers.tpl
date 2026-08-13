{{/*
Common labels
*/}}
{{- define "lmotel.labels" -}}
{{ include "lmutil.generic.labels" . }}
app.kubernetes.io/component: lmotel-collector
{{ include "lmutil.selectorLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
Common Annotations
*/}}
{{- define "lmotel.annotations" -}}
logicmonitor.com/provider: lm-container
{{- if .Values.annotations }}
{{ toYaml .Values.annotations }}
{{- end }}
{{- end }}

{{- define "lmotel-image" -}}
"{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- end -}}

{{- define "lmotel-logs-image" -}}
"{{ .Values.logs.image.repository }}:{{ .Values.logs.image.tag | default .Chart.AppVersion }}"
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "fluentbit.serviceAccountName" -}}
{{- default (include "lmutil.fullname" .)}}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "ingress.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "networking.k8s.io/v1" -}}
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
    {{- print "networking.k8s.io/v1beta1" -}}
  {{- else -}}
    {{- print "extensions/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/* Return if ingress supports pathType. */}}
{{/* pathType was added to networking.k8s.io/v1beta1 in Kubernetes 1.18 */}}
{{- define "ingress.supportsPathType" -}}
  {{- or (eq (include "ingress.isStable" .) "true") (and (eq (include "ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) -}}
{{- end -}}

{{/*
Check Ingress stability 
*/}}
{{- define "ingress.isStable" -}}
  {{- eq (include "ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Did the user set global.userDefinedSecret?
*/}}
{{- define "lmotel.userSecretSet" -}}
{{- if .Values.global.userDefinedSecret }}true{{ end -}}
{{- end -}}

{{/*
Return the credentials Secret name:
- If global.userDefinedSecret is provided, use that.
- Otherwise fall back to chart-managed Secret <fullname>.
*/}}
{{- define "lmotel.credsSecretName" -}}
{{- if .Values.global.userDefinedSecret -}}
{{- .Values.global.userDefinedSecret -}}
{{- else -}}
{{- include "lmutil.fullname" . -}}
{{- end -}}
{{- end -}}

{{/* True if we have any creds in any source (used by template fail-guard) */}}
{{- define "lmotel.credsProvided" -}}
{{- $uds := default "" .Values.global.userDefinedSecret -}}
{{- $ga := default "" .Values.global.accessID -}}
{{- $gk := default "" .Values.global.accessKey -}}
{{- $va := default "" .Values.lm.access_id -}}
{{- $vk := default "" .Values.lm.access_key -}}
{{- $vb := default "" .Values.lm.bearer_token -}}
{{- if or (ne $uds "")
          (and (ne $ga "") (ne $gk ""))
          (and (ne $va "") (ne $vk ""))
          (ne $vb "") -}}true{{- end -}}
{{- end -}}

{{/*
Emit a secretKeyRef block given a key name.
Usage:
  {{ include "lmotel.secretKeyRef" (dict "ctx" . "key" "bearerToken") | nindent 10 }}
*/}}
{{- define "lmotel.secretKeyRef" -}}
name: {{ include "lmotel.credsSecretName" .ctx }}
key: {{ .key }}
optional: true
{{- end -}}

{{/*
Validate credentials + account at render time.
Collector uses LMv1 first, then bearer; chart requires at least one complete set:
- LMv1: accessID+accessKey in user Secret, or global.accessID+global.accessKey, or lm.access_id+lm.access_key
- Bearer: bearerToken in user Secret, or lm.bearer_token
*/}}
{{- define "lmotel.assertInputs" -}}
{{- $ns := .Release.Namespace -}}
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
      (ne (default "" .Values.lm.account) "")
      (ne (default "" .Values.global.account) "")
      (and (ne $uds "") ($secHas.account | default false)) -}}
{{- if not $hasAccount -}}
  {{- fail "Account name missing: set lm.account or global.account, or provide Secret with key 'account' via global.userDefinedSecret." -}}
{{- end -}}

{{- /* 2) At least one complete credential set (LMv1 pair OR bearer) */ -}}
{{- $hasLMv1FromSecret := and (ne $uds "") ($secHas.accessID | default false) ($secHas.accessKey | default false) -}}
{{- $hasLMv1FromGlobal := and (ne (default "" .Values.global.accessID) "")
                              (ne (default "" .Values.global.accessKey) "") -}}
{{- $hasLMv1FromValues := and (ne (default "" .Values.lm.access_id) "")
                              (ne (default "" .Values.lm.access_key) "") -}}
{{- $hasBearerFromSecret := and (ne $uds "") ($secHas.bearerToken | default false) -}}
{{- $hasBearerFromValues := ne (default "" .Values.lm.bearer_token) "" -}}
{{- $hasCreds := or $hasLMv1FromSecret $hasLMv1FromGlobal $hasLMv1FromValues $hasBearerFromSecret $hasBearerFromValues -}}
{{- if not $hasCreds -}}
  {{- fail "No complete LM credentials: provide LMv1 (accessID+accessKey in Secret, or global.accessID+global.accessKey, or lm.access_id+lm.access_key) and/or bearer (bearerToken in Secret or lm.bearer_token). Collector prefers LMv1 when both are available." -}}
{{- end -}}
{{- end -}}