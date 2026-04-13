resource "google_service_account" "api_sa" {
  account_id   = "${var.app_name}-sa"
  display_name = "Cloud Run — API predicción retraso (FastAPI)"
  description  = "Identidad en runtime del servicio; no usar cuenta por defecto del proyecto."

  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "api_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

# Invocación pública (Locust / challenge). Compatible con provider google 5.0.x.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
