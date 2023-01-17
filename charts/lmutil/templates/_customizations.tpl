{{- define "lmutil.custom-pod-sec-context-nonroot" }}
{{ if eq (include "lmutil.is-openshift" .) "true" }}
runAsUser: 1000670001
fsGroup: 1000670001
runAsGroup: 1000670001
runAsNonRoot: true
{{- end }}
{{- end }}


{{- define "lmutil.custom-container-sec-context-nonroot" }}
{{ if eq (include "lmutil.is-openshift" .) "true" }}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
seccompProfile:
  type: RuntimeDefault
{{- end }}
{{- end }}
