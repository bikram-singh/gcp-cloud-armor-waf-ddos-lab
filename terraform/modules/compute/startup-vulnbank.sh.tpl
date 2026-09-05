#!/bin/bash
set -euo pipefail

# Fast, reliable boot: install Docker + compose plugin + a minimal gcloud CLI
# (for the Artifact Registry docker credential helper only — no build step,
# no git clone, no pip install happens here). This is the whole reason we
# went with Option B: everything below is package installs and container
# pulls, nothing that depends on GitHub being reachable at boot time.

apt-get update -y
apt-get install -y ca-certificates curl gnupg apt-transport-https

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# gcloud CLI (credential helper only — uses the VM's attached service
# account via the metadata server, no interactive login needed)
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update -y && apt-get install -y google-cloud-cli
gcloud auth configure-docker ${region}-docker.pkg.dev --quiet

mkdir -p /opt/vuln-bank
cat > /opt/vuln-bank/docker-compose.yml <<EOF
services:
  db:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${db_name}
      POSTGRES_USER: ${db_user}
      POSTGRES_PASSWORD: ${db_password}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${db_user}"]
      interval: 5s
      timeout: 5s
      retries: 10
    volumes:
      - pgdata:/var/lib/postgresql/data

  web:
    image: ${vulnbank_image}
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "5000:5000"
    environment:
      DB_NAME: ${db_name}
      DB_USER: ${db_user}
      DB_PASSWORD: ${db_password}
      DB_HOST: db
      DB_PORT: 5432
      # DEEPSEEK_API_KEY intentionally left unset — AI chat agent stays in
      # mock mode / disabled, out of scope for this lab (see
      # vulnerable-app/NOTES.md)

volumes:
  pgdata:
EOF

cd /opt/vuln-bank
docker compose up -d
