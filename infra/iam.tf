resource "google_service_account" "api_sa" {
  account_id   = "${var.app_name}-sa"
  display_name = "Cloud Run — flight delay prediction API (FastAPI)"
  description  = "Runtime identity for the service; avoids the project default account."

  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "api_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

# Public invocation (Locust / challenge). Works with google provider 5.0.x.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
