{{/*
Common name
*/}}
{{- define "atlas-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fullname
*/}}
{{- define "atlas-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
Uses index function for hyphenated keys (P6 Go template fix)
WRONG:   {{ .Values.labels.cost-center }}       — Go treats hyphen as subtraction
CORRECT: {{ index .Values.labels "cost-center" }}
*/}}
{{- define "atlas-platform.labels" -}}
app.kubernetes.io/name: {{ include "atlas-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
cost-center: {{ index .Values.labels "cost-center" | default "atlas-learning" }}
team: {{ .Values.labels.team | default "platform" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "atlas-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atlas-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}