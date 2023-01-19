{{- define "lmutil.default-pod-sec-context-nonroot"  }}
{{ if eq (include "lmutil.is-openshift" .) "true" }}
runAsUser: 1000670001
fsGroup: 1000670001
runAsGroup: 1000670001
{{- else }}
runAsUser: 2000
fsGroup: 2000
runAsGroup: 2000
{{- end }}
runAsNonRoot: true
{{- end }}


{{- define "lmutil.default-container-sec-context-nonroot" }}
{{ if eq (include "lmutil.is-openshift" .) "true" }}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
seccompProfile:
  type: RuntimeDefault
{{- end }}
{{- end }}
