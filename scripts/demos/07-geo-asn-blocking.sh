#!/bin/bash
# Demonstrates: rules-geo-based.tf — denies traffic from region_code 'US'.
#
# HONEST LIMITATION: Cloud Armor determines region from GeoIP lookup on the
# real source IP — not spoofable via headers or curl flags. Running this
# script from India (or anywhere outside the US) should show ALLOWED;
# to see the DENY case you need a request that genuinely originates from
# a US IP. The reliable way: spin up a temporary Compute Engine VM in
# us-central1 (this lab's own region) and curl from there via SSH:
#
#   gcloud compute instances create temp-us-test-vm \
#     --zone=us-central1-a --machine-type=e2-small \
#     --image-family=debian-12 --image-project=debian-cloud
#   gcloud compute ssh temp-us-test-vm --zone=us-central1-a \
#     --command="curl -sk -o /dev/null -w 'HTTP %{http_code}\n' https://${VULNBANK_LB_IP}/"
#   gcloud compute instances delete temp-us-test-vm --zone=us-central1-a --quiet
#
# The ASN rule (also in rules-geo-based.tf's neighbor rules-ip-based.tf)
# has the same limitation — you can't easily route your own traffic
# through an arbitrary ASN, so that portion is best understood by reading
# the CEL syntax rather than fully reproduced end-to-end in this lab.
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "Hitting vuln-bank LB from your current location:"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${VULNBANK_LB_IP}/"
echo "(Expect 200 if you're outside the US — the geo-deny rule only blocks US-origin traffic)"
