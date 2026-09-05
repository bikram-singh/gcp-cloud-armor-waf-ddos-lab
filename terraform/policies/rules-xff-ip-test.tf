# Empty on purpose -- the XFF_IP investigation this file supported is
# complete and CONFIRMED. See rules-user-ip-header.tf for the final
# write-up and scripts/demos/xff-ip-test.sh for the test that proved it.
# Kept as an empty file (rather than deleted) so the module wiring in
# environments/lab/main.tf (module.policies.xff_ip_test_rules) does not
# need to be un-wired -- an empty list here is a no-op in the concat().
locals {
  xff_ip_test_rules = []
}
