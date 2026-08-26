{{- define "hackertone-games.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hackertone-games.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "hackertone-games.labels" -}}
app.kubernetes.io/name: {{ include "hackertone-games.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "hackertone-games.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hackertone-games.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hackertone-games.env" -}}
{{- required "values.env 가 필요합니다 (deploy/env.yaml)" .Values.env -}}
{{- end -}}

{{- define "hackertone-games.publicHost" -}}
{{- printf "%s.external.kr" . -}}
{{- end -}}

{{- define "hackertone-games.hubScaled" -}}
{{- if has .folder (.root.Values.hub.scale.folders | default list) }}true{{ end -}}
{{- end -}}

{{- define "hackertone-games.hubReplicas" -}}
{{- if eq (include "hackertone-games.hubScaled" .) "true" -}}
{{- .root.Values.hub.scale.replicaCount -}}
{{- else -}}
{{- .root.Values.hub.replicaCount -}}
{{- end -}}
{{- end -}}

{{- define "hackertone-games.hubRedisUrl" -}}
{{- $base := required "redis.url 이 필요합니다" .root.Values.redis.url | trimSuffix "/" -}}
{{- $id := required "hubs[].id 가 필요합니다" .hub.id -}}
{{- $slots := .root.Values.redis.slots | default dict -}}
{{- $db := index $slots $id -}}
{{- if not $db -}}
{{- fail (printf "redis.slots.%s 가 없습니다" $id) -}}
{{- end -}}
{{- printf "%s/%d" $base (int $db) -}}
{{- end -}}
