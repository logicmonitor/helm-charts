{{/* vim: set filetype=mustache: */}}

{{- define "collector-config" -}}
replicas: {{ .Values.collector.replicas }}
size: {{ .Values.collector.size | quote}}
useEA: {{ .Values.collector.useEA | default false}}
version: {{ .Values.collector.version | default 0 }}
lm:
  escalationChainID: {{ .Values.collector.lm.escalationChainID | default 0 }}
{{- end -}}
