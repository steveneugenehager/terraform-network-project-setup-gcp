variable "billing_account" {
  description = "Billing account ID to link the host projects to."
  type        = string
  sensitive   = true
}

variable "terraform_service_account" {
  description = "Email of the Terraform service account created by the bootstrap."
  type        = string
}

variable "state_bucket" {
  description = "Terraform state bucket from the bootstrap, used to read the folders state."
  type        = string
}

variable "folders_state_prefix" {
  description = "State prefix of the folders configuration."
  type        = string
  default     = "org/folders"
}

variable "project_prefix" {
  description = "Short prefix that keeps project IDs globally unique, e.g. your initials."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,7}$", var.project_prefix))
    error_message = "Use 2-8 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "environments" {
  description = "Environment folder names (keys in the folders output) mapped to short names used in project IDs."
  type        = map(string)
  default = {
    development   = "dev"
    nonproduction = "nonprod"
    production    = "prod"
  }
}

variable "host_project_apis" {
  description = "APIs enabled in every host project."
  type        = list(string)
  default = [
    "compute.googleapis.com", # VPCs, subnets, firewall rules, NAT
    "dns.googleapis.com",     # private DNS zones, later
  ]
}

variable "deletion_policy" {
  description = "PREVENT protects host projects from terraform destroy; set DELETE deliberately to remove them."
  type        = string
  default     = "PREVENT"

  validation {
    condition     = contains(["PREVENT", "DELETE", "ABANDON"], var.deletion_policy)
    error_message = "Must be PREVENT, DELETE, or ABANDON."
  }
}

variable "iam_propagation_wait" {
  description = "Pause after granting Shared VPC Admin, so the grant takes effect before it is used."
  type        = string
  default     = "90s"
}
