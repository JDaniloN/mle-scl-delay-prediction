variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "GCP region for Artifact Registry and Cloud Run"
  default     = "us-central1"
}

variable "app_name" {
  type        = string
  description = "Base name for the Cloud Run service and related resource prefixes"
  default     = "mlops-challenge-api"
}

variable "image" {
  type        = string
  description = "Full image URI in Artifact Registry (including tag), e.g. REGION-docker.pkg.dev/PROJECT/REPO_ID/delay-api:sha"
}

variable "service_cpu" {
  type        = string
  description = "CPU per instance (Cloud Run v2)"
  default     = "1"
}

variable "service_memory" {
  type        = string
  description = "Memory per instance (CSV load + fit at startup can be heavy)"
  default     = "2Gi"
}

variable "min_instances" {
  type        = number
  description = "Minimum instances (1 reduces cold start during review; 0 saves cost)"
  default     = 1
}

variable "max_instances" {
  type        = number
  description = "Upper bound on concurrent instances"
  default     = 3
}

variable "service_timeout" {
  type        = string
  description = "Maximum request timeout (includes slow container startup)"
  default     = "300s"
}

variable "cpu_request_based" {
  type        = bool
  description = "true: CPU only while handling requests (request-based billing). false: CPU always allocated (instance-time billing)."
  default     = true
}
