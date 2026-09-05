#!/bin/bash
# Demonstrates: rules-path-based.tf — CEL path matching against nginx's
# /goodpath and /badpath content (served by the nginx VM's startup script).
set -euo pipefail
cd "$(dirname "$0")"
source ./_env.sh

echo "GET /goodpath/ — expect 200"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${NGINX_LB_IP}/goodpath/"

echo "GET /badpath/ — expect 403 (denied by rules-path-based.tf)"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${NGINX_LB_IP}/badpath/"

echo "GET / (root) — expect 200"
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://${NGINX_LB_IP}/"
