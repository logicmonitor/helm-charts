{{/*
Common labels
*/}}
{{- define "lm-container.labels" -}}
{{ include "lmutil.generic.labels" . }}
{{ include "lmutil.selectorLabels" . }}
{{- end }}

{{- define "lm-container.annotations" -}}
{{- end }}
