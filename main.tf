# ==================================================================================================
# File:        main.tf
# Module:      terraform-network-project-setup-gcp
# Description: Shared VPC host projects, their APIs, Shared VPC Admin grant, and host enablement.
# ==================================================================================================
#
# Change History
# --------------------------------------------------------------------------------------------------
# Date        Author                     Version  Description
# ----------  -------------------------  -------  --------------------------------------------------
# 2026-10-04  Steve Hager                1.0.0    Initial creation.
# 2026-10-09  Steve Hager                1.1.0    Place host projects and the Shared VPC Admin
#                                                 grant in each environment's infrastructure
#                                                 subfolder (subfolder_ids output) instead of the
#                                                 environment folder.
# --------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Inputs from earlier stages
# ---------------------------------------------------------------------------

data "terraform_remote_state" "folders" {
  backend = "gcs"
  config = {
    bucket                      = var.state_bucket
    prefix                      = var.folders_state_prefix
    impersonate_service_account = var.terraform_service_account
  }
}

locals {
  # Host projects go in each environment's infrastructure subfolder,
  # keyed "<env>/<subfolder>" in the folders output.
  subfolder_ids = data.terraform_remote_state.folders.outputs.subfolder_ids
  host_folder_keys = {
    for env, _ in var.environments : env => "${env}/${var.host_subfolder}"
  }

  # One entry per (environment, API) pair, for google_project_service.
  host_services = {
    for pair in setproduct(keys(var.environments), var.host_project_apis) :
    "${pair[0]}|${pair[1]}" => { env = pair[0], api = pair[1] }
  }
}

resource "random_id" "suffix" {
  byte_length = 2
}

# ---------------------------------------------------------------------------
# Host projects: one per environment, each in that environment's
# infrastructure subfolder.
# They hold only networking resources, never workloads.
# ---------------------------------------------------------------------------

resource "google_project" "host" {
  for_each = var.environments

  name            = "prj-${each.value}-net-host"
  project_id      = "${var.project_prefix}-${each.value}-net-host-${random_id.suffix.hex}"
  folder_id       = trimprefix(lookup(local.subfolder_ids, local.host_folder_keys[each.key], ""), "folders/")
  billing_account = var.billing_account
  deletion_policy = var.deletion_policy

  # Skip the "default" network and its permissive firewall rules;
  # the network stage builds a custom VPC instead.
  auto_create_network = false

  labels = {
    environment = each.value
    purpose     = "shared-vpc-host"
    managed_by  = "terraform"
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.subfolder_ids), local.host_folder_keys[each.key])
      error_message = "No folder '${local.host_folder_keys[each.key]}' in the folders state. Check var.environments and var.host_subfolder against the subfolder_ids output."
    }
  }
}

resource "google_project_service" "host" {
  for_each = local.host_services

  project            = google_project.host[each.value.env].project_id
  service            = each.value.api
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Shared VPC Admin for the Terraform service account, on each host
# project's subfolder. Enabling a Shared VPC host requires this role at the
# folder or organization level; owning the project is not enough.
# ---------------------------------------------------------------------------

resource "google_folder_iam_member" "xpn_admin" {
  for_each = var.environments

  folder = local.subfolder_ids[local.host_folder_keys[each.key]]
  role   = "roles/compute.xpnAdmin"
  member = "serviceAccount:${var.terraform_service_account}"
}

resource "time_sleep" "iam_propagation" {
  create_duration = var.iam_propagation_wait

  depends_on = [google_folder_iam_member.xpn_admin]
}

# ---------------------------------------------------------------------------
# Designate each project as a Shared VPC host.
# ---------------------------------------------------------------------------

resource "google_compute_shared_vpc_host_project" "host" {
  for_each = var.environments

  project = google_project.host[each.key].project_id

  depends_on = [
    google_project_service.host,
    time_sleep.iam_propagation,
  ]
}
