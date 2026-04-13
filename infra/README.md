# Infraestructura (Terraform)

## Validación local (sin aplicar en GCP)

Con Terraform instalado y en el PATH:

```powershell
cd infra
terraform init -backend=false
terraform validate
terraform fmt -check
```

Con backend GCS configurado en `provider.tf`, usa `terraform init` sin `-backend=false`.

## Orden recomendado

1. Copia `terraform.tfvars.example` → `terraform.tfvars` y rellena `project_id` e `image`.
2. Opcional: crea bucket de estado y descomenta `backend "gcs"` en `provider.tf`.
3. `terraform init` y `terraform apply` **solo** si la imagen ya existe en Artifact Registry, o aplica en dos fases:
   - Primera opción: `terraform apply -target=google_project_service.services -target=google_artifact_registry_repository.repo`, luego `docker build` / `docker push`, actualiza `image`, y `terraform apply` completo.
   - Segunda opción: `docker push` primero y luego `terraform apply` de una vez.
4. `terraform output api_endpoint` → copia la URL al `Makefile` (`STRESS_URL`) y al POST del challenge.

La invocación pública se concede con **`roles/run.invoker`** para **`allUsers`** en `iam.tf` (válido en cualquier 5.x). Si subes el provider a **>= 5.43**, puedes optar por `invoker_iam_disabled = true` en el servicio y quitar ese binding.

**CPU / facturación:** por defecto `cpu_request_based = true` en `variables.tf` → `cpu_idle = true` en Cloud Run v2 = **solo CPU durante el procesamiento de solicitudes** (modelo basado en solicitudes). Con `cpu_request_based = false` pasas a **CPU siempre asignada** (modelo tipo instancia).

## Imagen Docker

El nombre del repositorio en AR es `${app_name}-repo`. La URI de imagen debe usar el **repository_id** (p. ej. `mlops-challenge-api-repo`).

Desde la **raíz del repositorio** (donde está el `Dockerfile`):

```bash
docker build -t REGION-docker.pkg.dev/PROJECT/mlops-challenge-api-repo/delay-api:1 .
docker push REGION-docker.pkg.dev/PROJECT/mlops-challenge-api-repo/delay-api:1
```

Ajusta `image` en `terraform.tfvars` al mismo valor.
