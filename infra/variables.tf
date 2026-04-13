variable "project_id" {
  type        = string
  description = "ID del proyecto de Google Cloud"
}

variable "region" {
  type        = string
  description = "Región de GCP para Artifact Registry y Cloud Run"
  default     = "us-central1"
}

variable "app_name" {
  type        = string
  description = "Nombre base del servicio Cloud Run y prefijos de recursos relacionados"
  default     = "mlops-challenge-api"
}

variable "image" {
  type        = string
  description = "URI completa de la imagen en Artifact Registry (incluye tag), p. ej. REGION-docker.pkg.dev/PROJECT/REPO_ID/delay-api:sha"
}

variable "service_cpu" {
  type        = string
  description = "CPU por instancia (Cloud Run v2)"
  default     = "1"
}

variable "service_memory" {
  type        = string
  description = "Memoria por instancia (arranque con CSV + fit puede ser pesado)"
  default     = "2Gi"
}

variable "min_instances" {
  type        = number
  description = "Instancias mínimas (1 reduce cold start en revisión; 0 ahorra coste)"
  default     = 1
}

variable "max_instances" {
  type        = number
  description = "Tope de instancias concurrentes"
  default     = 3
}

variable "service_timeout" {
  type        = string
  description = "Timeout máximo por petición (incluye arranque lento del contenedor)"
  default     = "300s"
}

variable "cpu_request_based" {
  type        = bool
  description = "true: CPU solo durante solicitudes (facturación basada en solicitudes). false: CPU siempre asignada (facturación por tiempo de instancia)."
  default     = true
}
