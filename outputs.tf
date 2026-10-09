# ==================================================================================================
# File:        outputs.tf
# Module:      terraform-network-project-setup-gcp
# Description: Host project IDs and numbers by environment, read by the VPC stage.
# ==================================================================================================
#
# Change History
# --------------------------------------------------------------------------------------------------
# Date        Author                     Version  Description
# ----------  -------------------------  -------  --------------------------------------------------
# 2026-10-04  Steve Hager                1.0.0    Initial creation.
# --------------------------------------------------------------------------------------------------

output "host_project_ids" {
  description = "Shared VPC host project IDs by environment folder name."
  value       = { for env, p in google_project.host : env => p.project_id }
}

output "host_project_numbers" {
  description = "Host project numbers by environment folder name."
  value       = { for env, p in google_project.host : env => p.number }
}
