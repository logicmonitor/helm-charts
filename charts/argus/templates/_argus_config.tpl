{{/* vim: set filetype=mustache: */}}

{{- define "argus-config" -}}
collectorSetController:
{{- if .Values.global.collectorsetServiceNameSuffix }}
  address: {{ (printf "%s-%s" .Release.Name .Values.global.collectorsetServiceNameSuffix) | trunc 63 | trimSuffix "-" | quote }}
{{- else }}
  address: {{ (default "collectorset-controller" .Values.collectorsetcontroller.address) | quote }}
{{- end }}
  port: {{ (default 50000 .Values.collectorsetcontroller.port) }}
clusterName: {{ required "A valid .Values.clusterName entry is required!" .Values.clusterName }}
log:
  level: {{ .Values.log.level | quote }}
etcdDiscoveryToken: {{ .Values.etcdDiscoveryToken | quote }}
clusterTreeParentID: {{ .Values.clusterTreeParentID }}
resourceContainerID: {{ .Values.resourceContainerID }}
overview:
 {{- toYaml .Values.overview | nindent 2 }}
enableLegacyResourceTree: {{ .Values.enableLegacyResourceTree }}
globalDeleteAfterDuration: {{ .Values.lm.resource.globalDeleteAfterDuration | default "P0DT0H0M0S" }}
{{- if .Values.telemetryCronString }}
telemetryCronString: {{ .Values.telemetryCronString | quote }}
{{- end }}
ignoreSSL: {{ .Values.ignoreSSL }}
daemons:
  lmCacheSync:
    {{- toYaml .Values.daemons.lmCacheSync | nindent 4 }}
    minInterval: 5m
  watcher:
    bulkSyncInterval: {{ .Values.daemons.watcher.bulkSyncInterval | quote }}
    minInterval: 10m
    runner:
      {{- toYaml .Values.daemons.watcher.runner | nindent 6 }}
    {{- if .Values.daemons.watcher.sysIpsWaitTimeout }}
    sysIpsWaitTimeout: {{ .Values.daemons.watcher.sysIpsWaitTimeout }}
    {{- end }}
  lmResourceSweeper:
    {{- toYaml .Values.daemons.lmResourceSweeper | nindent 4 }}
    minInterval: 10m
    scheduledDeleteAfter: {{ .Values.lm.resource.globalDeleteAfterDuration | default "P0DT0H0M0S" }}
  worker:
    {{- toYaml .Values.daemons.worker | nindent 4 }}
resourceGroupProps:
  cluster:
  {{- include "cluster.extraprops" . | nindent 4 }}
  nodes:
  {{- toYaml .Values.lm.resourceGroup.extraProps.nodes | nindent 4 }}
  etcd:
  {{- toYaml .Values.lm.resourceGroup.extraProps.etcd | nindent 4 }}
{{- if .Values.selfMonitor }}
selfMonitor:
  {{- toYaml .Values.selfMonitor | nindent 2}}
{{- end }}
monitoring:
  disable:
    {{- include "monitoring.disable" . | nindent 4 }}
  annotations:
    ignore:
      {{- include "monitoring.annotations.ignore" . | nindent 6}}
  labels:
    ignore:
      {{- toYaml .Values.monitoring.labels.ignore | nindent 6}}
alerting:
  disable:
    {{- include "alerting.disable" . | nindent 4 }}
lm:
  opsNotes:
    {{- toYaml .Values.lm.opsNotes | nindent 4}}
{{- if .Values.debug }}
{{- toYaml .Values.debug | nindent 0 }}
{{- end }}
{{- if .Values.proxy.url }}
proxy:
  url: {{ .Values.proxy.url }}
{{- else if .Values.global.proxy.url }}
proxy:
  url: {{ .Values.global.proxy.url }}
{{- end }}
{{- end -}}
