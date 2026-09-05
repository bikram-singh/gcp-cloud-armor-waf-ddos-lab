#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/html/goodpath /var/www/html/badpath

cat > /var/www/html/index.html <<'EOF'
<html><body><h1>Cloud Armor Lab — nginx backend</h1>
<p>Try <a href="/goodpath/">/goodpath/</a> and <a href="/badpath/">/badpath/</a>
to see the path-based CEL rule demo.</p></body></html>
EOF

cat > /var/www/html/goodpath/index.html <<'EOF'
<html><body><h1>Good path — allowed</h1></body></html>
EOF

cat > /var/www/html/badpath/index.html <<'EOF'
<html><body><h1>Bad path — should be denied by rules-path-based.tf</h1></body></html>
EOF

systemctl restart nginx
systemctl enable nginx
