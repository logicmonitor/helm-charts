{{- /*
These templates take following arguments:
1. top context
2. name of the scc object
3. service account users to associate with scc in format: "<namespace>:<service account name>"
*/ -}}
{{- define "lmutil.openshift-scc-nonroot-v2" -}}
{{- $top := first . -}}
{{- $name := (index . 1) -}}
{{- $saUsers := (index . 2) -}}
{{- if and (eq (include "lmutil.is-openshift" $top) "true") ($top.Capabilities.APIVersions.Has "security.openshift.io/v1") -}}
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: false
allowPrivilegedContainer: false
allowedCapabilities:
  - NET_BIND_SERVICE
  - NET_RAW
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups: [ ]
kind: SecurityContextConstraints
metadata:
  labels:
    {{ include "lmutil.generic.labels" $top | nindent 4 }}
  annotations:
    include.release.openshift.io/ibm-cloud-managed: "true"
    include.release.openshift.io/self-managed-high-availability: "true"
    kubernetes.io/description: nonroot provides all features of the restricted SCC
      but allows users to run with any non-root UID.  The user must specify the UID
      or it must be specified on the by the manifest of the container runtime. On
      top of the legacy 'nonroot' SCC, it also requires to drop ALL capabilities and
      does not allow privilege escalation binaries. It will also default the seccomp
      profile to runtime/default if unset, otherwise this seccomp profile is required.
  name: {{ $name }}
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
  - ALL
runAsUser:
  type: MustRunAsNonRoot
seLinuxContext:
  type: MustRunAs
seccompProfiles:
  - runtime/default
supplementalGroups:
  type: RunAsAny
{{ if gt ($saUsers | len) 0 }}
users:
{{ range $saUsers }}
  - system:serviceaccount:{{ . }}
{{- end }}
{{- end }}
volumes:
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - projected
  - secret
{{- end -}}
{{- end -}}


{{- /*
These templates take following arguments:
1. top context
2. name of the scc object
3. service account users to associate with scc in format: "<namespace>:<service account name>"
*/ -}}
{{- define "lmutil.openshift-scc-anyuid" -}}
{{- $top := first . -}}
{{- $name := (index . 1) -}}
{{- $saUsers := (index . 2) -}}
{{- if and (eq (include "lmutil.is-openshift" $top) "true") ($top.Capabilities.APIVersions.Has "security.openshift.io/v1") -}}
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities:
  - NET_RAW
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups:
  - system:cluster-admins
kind: SecurityContextConstraints
metadata:
  labels:
    {{ include "lmutil.generic.labels" $top | nindent 4 }}
  annotations:
    include.release.openshift.io/ibm-cloud-managed: "true"
    include.release.openshift.io/self-managed-high-availability: "true"
    kubernetes.io/description: anyuid provides all features of the restricted SCC
      but allows users to run with any UID and any GID.
  name: {{ $name }}
priority: 10
readOnlyRootFilesystem: false
requiredDropCapabilities:
  - MKNOD
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
{{ if gt ($saUsers | len) 0 }}
users:
{{ range $saUsers }}
  - system:serviceaccount:{{ . }}
{{- end }}
{{- end }}
volumes:
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - projected
  - secret
{{- end -}}
{{- end -}}