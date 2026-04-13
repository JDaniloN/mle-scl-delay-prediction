# Infrastructure (Terraform)

## Local validation (no apply to GCP)

With Terraform installed and on your PATH:

```powershell
cd infra
terraform init -backend=false
terraform validate
terraform fmt -check
```

With a GCS backend configured in `provider.tf`, run `terraform init` without `-backend=false`.

## Order of operations I followed

1. Started from `terraform.tfvars.example` → `terraform.tfvars` with `project_id` and `image` filled in.
2. Optional: state bucket and uncommented `backend "gcs"` block in `provider.tf`.
3. `terraform init` and `terraform apply` once the image existed in Artifact Registry, or in two phases:
   - First option: `terraform apply -target=google_project_service.services -target=google_artifact_registry_repository.repo`, then `docker build` / `docker push`, update `image`, then full `terraform apply`.
   - Second option: `docker push` first, then a single `terraform apply`.
4. `terraform output api_endpoint` → that URL went into the `Makefile` (`STRESS_URL`) and the challenge POST.

Public access is granted via **`roles/run.invoker`** for **`allUsers`** in `iam.tf` (valid on any 5.x). With provider **>= 5.43** you can use `invoker_iam_disabled = true` on the service and drop that binding.

**CPU / billing:** by default `cpu_request_based = true` in `variables.tf` → `cpu_idle = true` in Cloud Run v2 = **CPU only while processing requests** (request-based model). With `cpu_request_based = false` you move to **always-allocated CPU** (instance-style model).

## Docker image

The Artifact Registry repository name is `${app_name}-repo`. The image URI must use the **repository_id** (e.g. `mlops-challenge-api-repo`).

From the **repository root** (where the `Dockerfile` lives):

```bash
docker build -t REGION-docker.pkg.dev/PROJECT/mlops-challenge-api-repo/delay-api:1 .
docker push REGION-docker.pkg.dev/PROJECT/mlops-challenge-api-repo/delay-api:1
```

`image` in `terraform.tfvars` matches that tag/URI.
