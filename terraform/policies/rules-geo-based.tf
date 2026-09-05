# Geo-based blocking — mirrors the original lab's "deny all traffic from
# US region, allow traffic from other regions" advanced-mode demo.
# `origin.region_code` is a CEL field Cloud Armor populates from GeoIP data.
locals {
  geo_based_rules = [
    {
      priority    = 2020
      action      = "deny(403)"
      description = "Deny traffic originating from US region (swap country code to demo differently)"
      expression  = "origin.region_code == 'US'"
    },
  ]
}
