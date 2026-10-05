terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Partial configuration: values come from backend.hcl.
  #   terraform init -backend-config=backend.hcl
  backend "gcs" {}
}

provider "google" {
  impersonate_service_account = var.terraform_service_account
}
