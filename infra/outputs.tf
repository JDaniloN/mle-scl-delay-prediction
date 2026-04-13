output "api_endpoint" {
  description = "URL HTTPS pública del servicio (usar en STRESS_URL y en el POST del challenge)"
  value       = google_cloud_run_v2_service.api.uri
}

output "artifact_registry_repository_id" {
  description = "ID corto del repositorio (segmento de la ruta docker push)"
  value       = google_artifact_registry_repository.repo.repository_id
}

output "docker_push_prefix" {
  description = "Prefijo REGION-docker.pkg.dev/PROJECT/REPO_ID — añade /NOMBRE_IMAGEN:TAG al hacer docker tag/push"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "suggested_image_example" {
  description = "Ejemplo de URI de imagen coherente con este despliegue (sustituye el tag por el tuyo)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/delay-api:TAG"
}
