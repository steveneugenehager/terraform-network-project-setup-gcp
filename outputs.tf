output "host_project_ids" {
  description = "Shared VPC host project IDs by environment folder name."
  value       = { for env, p in google_project.host : env => p.project_id }
}

output "host_project_numbers" {
  description = "Host project numbers by environment folder name."
  value       = { for env, p in google_project.host : env => p.number }
}
