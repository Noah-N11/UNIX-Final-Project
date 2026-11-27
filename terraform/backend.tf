terraform {
  backend "gcs" {
    bucket = "cop3304-fall2026-terraform-state"
    prefix = "infrastructure/terraform/state"
  }
}