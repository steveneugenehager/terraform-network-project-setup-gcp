# ==================================================================================================
# File:        versions.tf
# Module:      terraform-network-project-setup-gcp
# Description: Terraform and provider versions, GCS backend, and impersonating provider.
# ==================================================================================================
#
# Change History
# --------------------------------------------------------------------------------------------------
# Date        Author                     Version  Description
# ----------  -------------------------  -------  --------------------------------------------------
# 2026-10-04  Steve Hager                1.0.0    Initial creation.
# 2026-10-09  Steve Hager                1.1.0    required_version >= 1.6 to match the bootstrap
#                                                 repo.
# --------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6"

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
