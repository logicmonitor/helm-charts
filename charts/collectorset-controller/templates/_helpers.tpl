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

These env vars are emitted statically into the Deployment so the manifest is
fully declarative and GitOps tools (Rancher Fleet, Argo CD) do not see drift.
This replaces a post-install Job that previously patched the Deployment env
based on a runtime lookup of the user-defined Secret.

Precedence enforced by the collectorset-controller binary (see
pkg/config/config.go, applySecretEnvOverrides): values from the user-defined
Secret win over the plaintext values rendered from .Values. Every
`*_FROM_SECRET` env var uses `optional: true` so a key missing from the
user-defined Secret simply leaves the override unset — the binary then falls
back to the plaintext env.
*/}}

{{- define "collectorset-controller.lm-credentials-and-proxy-details" -}}
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
{{- /* PROXY_USER: csc-specific secret key wins over generic, then plaintext */}}
{{- if .Values.global.userDefinedSecret }}
- name: PROXY_USER_FROM_SECRET_CSC
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: collectorProxyUser
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
{{- /* PROXY_PASS: csc-specific secret key wins over generic, then plaintext */}}
{{- if .Values.global.userDefinedSecret }}
- name: PROXY_PASS_FROM_SECRET_CSC
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.userDefinedSecret }}
      key: collectorProxyPass
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