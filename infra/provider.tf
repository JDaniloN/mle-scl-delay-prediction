terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # >= 5.43 adds useful Cloud Run v2 flags (`invoker_iam_disabled`, `deletion_protection`).
      # With only ~> 5.0, Terraform may resolve to 5.0.x and those arguments fail validation.
      version = ">= 5.43.0, < 7.0.0"
    }
  }

  # Optional GCS backend: once the bucket exists (gcloud storage buckets create ...), uncomment the `backend` block with the right bucket/prefix.
  # Terraform does not allow variables in backend blocks.
  # backend "gcs" {
  #   bucket = "delaybucket-tfstate"
  #   prefix = "delay-api/terraform"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
