# GCP Shared VPC Host Projects

Creates one Shared VPC host project per environment, each in its environment's
infrastructure subfolder:

```
Organization
├── fldr-lab
│   └── fldr-lab-infrastructure    └── prj-lab-net-host
└── fldr-dev
    └── fldr-dev-infrastructure    └── prj-dev-net-host
```

Add an environment (e.g. `prod = "prod"`) to `environments` once the folders
stage has created it.

Each project is linked to billing, has the Compute Engine and Cloud DNS APIs
enabled, has no default network, and is designated a Shared VPC host. The
networks themselves are built by the network stage.

## Dependencies

- **Bootstrap**: state bucket and Terraform service account. The service account
  needs Billing Account User (bootstrap `grant_billing_user = true`) and
  Project Creator and Folder Admin at the organization (granted when the
  bootstrap's `org_id` is set).
- **Folders**: each environment's `infrastructure` subfolder, read from the
  `subfolder_ids` output in state at `org/folders`.

This configuration grants the Terraform service account **Shared VPC Admin**
(`roles/compute.xpnAdmin`) on each infrastructure subfolder, which enabling a Shared
VPC host requires. It can do so because Folder Admin includes permission to
set folder IAM policy.

## Run

```bash
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform fmt && terraform validate
terraform plan -out=hosts.plan
terraform apply hosts.plan
```

The apply pauses about 90 seconds after granting Shared VPC Admin, so the grant
takes effect before the host projects are enabled. If enablement still fails
with a permission error, wait a minute and run `terraform apply` again; the
remaining step will complete.

State is stored at `gs://SEED_PROJECT_ID-tfstate/projects/network-hosts/`.

## Using the host project IDs

```hcl
data "terraform_remote_state" "network_hosts" {
  backend = "gcs"
  config = {
    bucket                      = "SEED_PROJECT_ID-tfstate"
    prefix                      = "projects/network-hosts"
    impersonate_service_account = "terraform-super-admin@SEED_PROJECT_ID.iam.gserviceaccount.com"
  }
}

locals {
  host_project_id = data.terraform_remote_state.network_hosts.outputs.host_project_ids["lab"]
}
```

## Verify

```bash
terraform output host_project_ids
gcloud compute shared-vpc organizations list-host-projects ORG_ID
gcloud compute networks list --project=HOST_PROJECT_ID   # should be empty
```
