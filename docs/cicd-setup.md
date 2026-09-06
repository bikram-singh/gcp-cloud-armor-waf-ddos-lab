# CI/CD Setup: GitHub Actions + HCP Terraform + GCP

This documents the actual, real setup required to get `.github/workflows/*.yml`
working end-to-end -- not the idealized version, the one confirmed by
actually triggering the workflows and fixing what broke, in order.

## Why this took six real fixes, not zero

Six genuinely distinct problems surfaced, each only visible by actually
running the workflow -- none of them were guessable in advance from
reading the YAML or the docs alone.

### 1. Per-step `env:` doesn't persist across steps

The original workflow set `TF_TOKEN_APP_TERRAFORM_IO` as an environment
variable on individual steps (e.g. "Setup Terraform"). GitHub Actions
does **not** carry a step's `env:` block into later steps -- each step
is its own shell invocation. The `terraform init` step had no token at
all, failing with `Required token could not be found`.

**Fix:** move `env:` to the **job level**, so every step in the job
inherits it. All three workflows now do this.

### 2. Stale or wrong HCP Terraform token

Confirmed the token secret's *name* existed, but the actual value was
either stale or never valid. GitHub never shows a secret's stored value
once saved, so when in doubt, just generate a fresh token in HCP
Terraform (**User Settings > Tokens**) and overwrite the secret.

### 3. Local execution mode does not auto-inject workspace variables

This project's HCP Terraform workspace runs in **Local execution mode**
(state storage only -- switched from Remote mode earlier in this
project because Remote mode could not resolve `../../modules` relative
paths). Remote mode auto-injects a workspace's stored Terraform
variables into the run; Local mode does not, because HCP Terraform
never actually executes the plan/apply in Local mode -- whatever runs
`terraform` (your machine, or here, the Actions runner) needs those
variables supplied itself.

Locally this is handled by a gitignored `terraform.tfvars` file, which
of course doesn't exist in a fresh Actions checkout. Confirmed via a
real run that hung indefinitely -- `terraform plan` was waiting on an
interactive prompt for `project_id` that a CI shell can never answer.

**Fix:** pass `TF_VAR_project_id` and `TF_VAR_vulnbank_image_tag` as
job-level env vars, sourced from repository **variables** (Settings >
Secrets and variables > Actions > Variables tab):
```
PROJECT_ID          = project-cloud-armor
VULNBANK_IMAGE_TAG  = <pinned vuln-bank commit hash>
```
Also added `-input=false` to every `terraform plan`/`apply`/`destroy`
invocation as a safety net -- any future missing variable now fails
fast and loud instead of hanging silently.

### 4. A stale state lock

A cancelled run (or a local `terraform plan` left running) can leave
the HCP Terraform workspace locked. The CLI's own `terraform
force-unlock <id>` frequently fails with "lock ID does not match" when
the workspace uses the `cloud` backend, because locking is actually
tracked by HCP Terraform's own run queue, not a simple lock file the
CLI can force-clear reliably.

**Fix:** go to the workspace directly in HCP Terraform's UI
(**Overview** tab) -- if it shows "Locked by \<user\>", click
**Unlock** there. This is the reliable fix; repeated CLI
`force-unlock` attempts with changing lock IDs are a symptom of this,
not a separate problem to solve via the CLI.

### 5. No GCP authentication on the Actions runner at all

The most fundamental gap: nothing in the original workflows ever
authenticated to GCP. `TF_TOKEN_APP_TERRAFORM_IO` only authenticates to
HCP Terraform for state storage -- a completely separate concern from
authenticating the `google`/`google-beta` Terraform providers
themselves to actually call the GCP API. Confirmed via a real error:
`could not find default credentials`.

**The org this project's GCP org (`gcpcloudhub.in`) blocks service
account key file creation entirely** (`constraints/iam.managed.disableServiceAccountKeyCreation`),
so a downloaded JSON key was never an option. The correct fix is
**Workload Identity Federation (WIF)** -- no long-lived credential
ever leaves GCP or sits in a GitHub secret.

Setup (one-time):
```bash
# 1. Service account for CI
gcloud iam service-accounts create github-actions-ci \
  --project=project-cloud-armor \
  --display-name="GitHub Actions CI for gcp-cloud-armor-waf-ddos-lab"

# 2. Workload Identity Pool + OIDC provider trusting GitHub's token issuer
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project=project-cloud-armor --location="global"

gcloud iam workload-identity-pools providers create-oidc "github-actions-provider" \
  --project=project-cloud-armor --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='<owner>/<repo>'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
# NOTE: --attribute-condition is required by current gcloud versions --
# it rejects an unconditioned provider outright (a real safety measure,
# confirmed via a real "must reference one of the provider's claims"
# error on the first attempt without it).

# 3. Let only this repo impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-ci@project-cloud-armor.iam.gserviceaccount.com \
  --project=project-cloud-armor \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/<owner>/<repo>"
```

Each workflow then adds, before any Terraform step:
```yaml
permissions:
  id-token: write   # required for WIF -- without this, auth silently fails differently

steps:
  - uses: google-github-actions/auth@v2
    with:
      workload_identity_provider: "projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider"
      service_account: "github-actions-ci@project-cloud-armor.iam.gserviceaccount.com"
```

### 6. Missing IAM roles on the CI service account -- found incrementally

Even with real GCP auth working, two more permission gaps surfaced,
each via its own distinct real error:

- **`Cloud Resource Manager API has not been used in project ... or it
  is disabled`** -- `google_project_service` resources check API
  status via Cloud Resource Manager, which wasn't enabled on the
  project at all:
  ```bash
  gcloud services enable cloudresourcemanager.googleapis.com --project=project-cloud-armor
  ```

- **`403: The caller does not have permission`** on
  `google_project_iam_member` resources -- managing OTHER service
  accounts' project-level IAM bindings needs its own distinct role,
  separate from resource-specific admin roles:
  ```bash
  gcloud projects add-iam-policy-binding project-cloud-armor \
    --member="serviceAccount:github-actions-ci@project-cloud-armor.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.projectIamAdmin"
  ```

## Final confirmed role set for `github-actions-ci`

```
roles/compute.admin
roles/compute.securityAdmin
roles/artifactregistry.admin
roles/iam.serviceAccountUser
roles/serviceusage.serviceUsageAdmin
roles/resourcemanager.projectIamAdmin
```
Plus `cloudresourcemanager.googleapis.com` and
`serviceusage.googleapis.com` enabled on the project (the latter is
needed for `serviceUsageAdmin` to function; the former for
`google_project_service` resources to check status at all).

## Debugging tools that actually helped

- `gh` (GitHub CLI) was far more reliable than the web UI for reading
  Actions logs -- `gh pr checks <n>` for a quick pass/fail summary,
  `gh run view <run-id> --log | Select-String -Pattern "Error" -Context 2,15`
  to pull just the relevant error text out of a huge log, rather than
  hunting through nested collapsible UI elements.
- Every fix in this list was found by triggering the workflow for
  real and reading the actual error -- none of these were predictable
  from the YAML alone. Budget for several real iterations the first
  time you wire up Terraform + GitHub Actions + GCP together, even
  with correct-looking config.
