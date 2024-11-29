{{- define "word-cloud-generator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "word-cloud-generator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{- define "word-cloud-generator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "word-cloud-generator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "word-cloud-generator.labels" -}}
helm.sh/chart: {{ include "word-cloud-generator.name" . }}
app.kubernetes.io/name: {{ include "word-cloud-generator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}