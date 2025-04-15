{{/* vim: set filetype=mustache: */}}

{{- define "filter-config" -}}
{{- $filterValues := .Values.filters }}
{{- if .Values.disableBatchingPods }}
{{- $disabledBatchingFilter := "contains(owner,\"Job,CronJob\") && type == \"pod\"" }}
{{- $filterValues = append .Values.filters ($disabledBatchingFilter) }}
{{- end }}
filters:
  {{ toYaml $filterValues | nindent 2 }}
{{- end -}}
