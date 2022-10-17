{{/* vim: set filetype=mustache: */}}

{{- define "trimmed-collector-config-agentConf" -}}
{{- $trimmedCollectorProps := list "jdbc" "perfmon" "wmi" "netapp" "esx" "xen" "mongo" "wineventlog" "snmptrap" "syslog"}}
{{- $propList := list  }}
{{- range $val := $trimmedCollectorProps }}
{{- $kv := dict}}
{{- $_ := set $kv "key" (printf "collector.%s.enable" $val) }}
{{- $_1 := set $kv "value" "false" }}
{{- $propList = append $propList $kv }}
trimmedCollectorAgentConf:
{{- toYaml $propList | nindent 2 }}
{{- end }}
{{- end }}


{{ define "collector-conf" }}
{{ $result := list }}

{{- $keys := dict }}
{{- range .Values.collector.collectorConf.agentConf }}
{{- $_ := set $keys .key true }}
{{- end }}

{{- if gt (len .Values.collector.collectorConf.agentConf) 0 }}
{{- $result = (concat $result .Values.collector.collectorConf.agentConf | uniq ) }}
{{- end }}

{{- if not .Values.collector.disableLightweightCollector }}
    {{- $abc := include "trimmed-collector-config-agentConf" . | fromYaml }}
    {{- $trimmedList := get $abc "trimmedCollectorAgentConf" }}
    {{- range $trimmedList }}
        {{- if not (hasKey $keys .key) }}
            {{- $result = append $result . }}
        {{- end }}
    {{- end }}
{{- end }}

resultList:
{{- toYaml $result | nindent 2 }}
{{- end }}