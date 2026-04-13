locals {
  apis = toset([
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
  ])
}

resource "google_project_service" "services" {
  for_each = local.apis

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.app_name}-repo"
  format        = "DOCKER"
  description   = "Docker images — SCL flight delay ML API"

  depends_on = [google_project_service.services]
}

resource "google_cloud_run_v2_service" "api" {
  name     = var.app_name
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"
  # Note: `deletion_protection` and `invoker_iam_disabled` exist on recent provider versions
  # (e.g. google >= ~5.43). With ~> 5.0 you may stay on 5.0.x without those fields; public access is wired in iam.tf.

  template {
    service_account = google_service_account.api_sa.email
    timeout         = var.service_timeout

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.service_cpu
          memory = var.service_memory
        }
        # true = request-based billing (CPU throttled outside requests).
        # false = CPU always allocated (instance-style / “always on” billing).
        cpu_idle          = var.cpu_request_based
        startup_cpu_boost = true
      }

      ports {
        container_port = 8080
      }
    }
  }

  depends_on = [
    google_project_service.services,
    google_artifact_registry_repository.repo,
    google_service_account.api_sa,
  ]
}
