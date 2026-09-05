# cloud-armor module

Four submodules, each a distinct Cloud Armor policy scope:

| Submodule | Scope | Status |
|---|---|---|
| `backend-policies/` | Global or regional backend security policy — the main WAF/rate-limit/redirect policy attached to your HTTPS LB's backend service | ✅ ready |
| `edge-policies/` | Edge security policy (`CLOUD_ARMOR_EDGE`) attached to a backend bucket — used for the Edge-vs-Backend precedence demo | ✅ ready |
| `hierarchical-policies/` | Org/folder-level policy enforcement (GA Sept 2025) | ⚠️ stub — verify resource schema, see README inside |
| `network-edge-policies/` | L3/L4 protection for passthrough Network LBs (`CLOUD_ARMOR_NETWORK`) | ⚠️ stub — verify resource schema, see README inside |

## Usage (backend-policies example)

```hcl
module "baseline_policy" {
  source      = "../../modules/cloud-armor/backend-policies"
  project_id  = var.project_id
  policy_name = "lab-baseline-policy"

  rules = [
    {
      priority    = 2147483647
      action      = "deny(403)"
      description = "Default deny-all"
      src_ip_ranges = ["*"]
    },
    {
      priority    = 10
      action      = "allow"
      description = "Allow all (demonstrates priority ordering vs default deny)"
      src_ip_ranges = ["*"]
    },
  ]
}
```

Each rule in `var.rules` is either an IP-match rule (`src_ip_ranges` set) or
a CEL-expression rule (`expression` set) — see `backend-policies/variables.tf`
for the full schema, including rate limiting, redirect, and header-injection
options. The `terraform/policies/*.tf` files in this repo build the actual
per-capability rule lists (baseline, IP-based, geo/ASN, path-based, rate
limit, redirect, preconfigured WAF, WAF tuning) and pass them into one or
more instances of this module from `environments/lab/main.tf`.
