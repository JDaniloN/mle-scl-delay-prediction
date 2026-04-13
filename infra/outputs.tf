output "api_endpoint" {
  description = "Public HTTPS URL of the service (use for STRESS_URL and the challenge POST)"
  value       = google_cloud_run_v2_service.api.uri
}

output "artifact_registry_repository_id" {
  description = "Short repository ID (segment in the docker push path)"
  value       = google_artifact_registry_repository.repo.repository_id
}

output "docker_push_prefix" {
  description = "Prefix REGION-docker.pkg.dev/PROJECT/REPO_ID — append /IMAGE_NAME:TAG for docker tag/push"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "suggested_image_example" {
  description = "Example image URI consistent with this stack (replace TAG with yours)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/delay-api:TAG"
}
