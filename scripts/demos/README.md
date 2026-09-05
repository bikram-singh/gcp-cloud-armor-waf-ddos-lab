# scripts/demos — how to run these

Each script exercises ONE already-deployed Cloud Armor rule (or rule set)
against the live lab environment via `curl`. They don't modify Terraform —
they just send traffic and show you the resulting behavior. Run them
**after** `terraform apply` has succeeded and both LBs are healthy (LB
health checks can take a couple of minutes to go green after first apply).

## Running these on Windows

These are bash scripts (loops, conditionals, `curl` flag combinations) —
that's a deliberate choice, bash is the natural fit for "send N requests
and check the response code" demos. On Windows, run them via:

**Git Bash** (you already have this if you have Git for Windows installed):
```powershell
& "C:\Program Files\Git\bin\bash.exe" .\scripts\demos\01-baseline-deny-allow.sh
```

**WSL**, if set up:
```powershell
wsl bash ./scripts/demos/01-baseline-deny-allow.sh
```

## One-time setup: capture your LB IPs

After `terraform apply`, get the two external IPs:

```powershell
cd terraform\environments\lab
terraform output -raw nginx_lb_ip
terraform output -raw vulnbank_lb_ip
```

Copy `_env.sh.example` in this folder to `_env.sh` and paste the two IPs
in. `_env.sh` is gitignored (see repo `.gitignore`) — every demo script
sources it automatically, so you only set the IPs in one place.

```powershell
Copy-Item .\scripts\demos\_env.sh.example .\scripts\demos\_env.sh
& "C:\Program Files\Git\bin\bash.exe" -c "sed -i 's/NGINX_LB_IP=.*/NGINX_LB_IP=<your-ip>/' scripts/demos/_env.sh"
```
(or just open `_env.sh` in a text editor and paste the IPs in directly —
simpler than the sed one-liner above if you're not comfortable with it)

## Why every curl call uses `-k`

The LBs use a self-signed cert (see
`terraform/modules/load-balancer/https-lb/main.tf`) since this lab has no
real domain. `-k` skips certificate verification — expected and fine for
a lab, never do this against anything real.

## Placeholder values you'll need to edit

Several rule files (`rules-ip-based.tf`, `rules-geo-based.tf`, etc.) use
placeholder IPs/ASNs/regions for documentation purposes. The
corresponding demo scripts note this inline — swap the placeholder in the
Terraform rule file and re-apply before expecting the "attacker" side of a
demo to behave as described against your own real traffic.
