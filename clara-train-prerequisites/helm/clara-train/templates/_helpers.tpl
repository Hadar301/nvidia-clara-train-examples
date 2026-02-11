{{/*
Expand the name of the chart.
*/}}
{{- define "clara-train.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clara-train.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clara-train.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clara-train.labels" -}}
helm.sh/chart: {{ include "clara-train.chart" . }}
{{ include "clara-train.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clara-train.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clara-train.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve namespace for resources
Use .Values.namespace if set, otherwise use .Release.Namespace
*/}}
{{- define "clara-train.namespace" -}}
{{- if .Values.namespace }}
{{- .Values.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Resolve ImageStream namespace
*/}}
{{- define "clara-train.imagestream.namespace" -}}
{{- if .Values.components.imagestream.namespace }}
{{- .Values.components.imagestream.namespace }}
{{- else }}
{{- include "clara-train.namespace" . }}
{{- end }}
{{- end }}
