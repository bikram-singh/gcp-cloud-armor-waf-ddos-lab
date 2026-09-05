output "nginx_lb_ip" {
  description = "External IP of the nginx-fronting LB — used by path-based demo scripts"
  value       = module.lb_nginx.external_ip
}

output "vulnbank_lb_ip" {
  description = "External IP of the vuln-bank-fronting LB — used by SQLi/XSS/rate-limit demo scripts"
  value       = module.lb_vulnbank.external_ip
}

output "vulnbank_lb_ipv6" {
  description = "External IPv6 address of the vuln-bank-fronting LB — used by 02b-ipv6-allow-deny.sh"
  value       = module.lb_vulnbank.external_ipv6
}

output "baseline_policy_name" {
  value = module.baseline_policy.policy_name
}
