terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # >= 5.43 añade flags útiles en Cloud Run v2 (`invoker_iam_disabled`, `deletion_protection`).
      # Si fijas solo ~> 5.0, Terraform puede quedarse en 5.0.x y esos argumentos fallan en validate.
      version = ">= 5.43.0, < 7.0.0"
    }
  }

  # Tras crear el bucket (gcloud storage buckets create ...), descomenta y ajusta.
  # Terraform no admite variables en backend.
  # backend "gcs" {
  #   bucket = "delaybucket-tfstate"
  #   prefix = "delay-api/terraform"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
