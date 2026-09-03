#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# Modified for d9 by Lauren (yocuri)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://directus.com/ | https://github.com/LaWebcapsule/d9

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
# PG_VERSION="17" setup_postgresql
# PG_DB_NAME="directus" PG_DB_USER="directus" setup_postgresql_db

DB_HOST="10.0.0.10"
DB_PORT="5432"
DB_DATABASE="d9_db"
DB_USER="d9user"

REDIS_HOST="10.0.0.100"
REDIS_PORT="6379"
read -rsp "PostgreSQL password: " DB_PASSWORD
echo
read -rsp "Redis password: " REDIS_PASSWORD
echo
read -rsp "Directus admin email: " DIRECTUS_ADMIN_EMAIL
echo
read -rsp "Directus admin password: " DIRECTUS_ADMIN_PASSWORD
echo
msg_info "Installing Directus fork d9"
mkdir -p /opt/d9/uploads /opt/d9/extensions
cd /opt/d9
$STD npm init -y
# DIRECTUS_VERSION=$(get_latest_github_release "directus/directus")
# $STD npm install --omit=dev "directus@${DIRECTUS_VERSION}"
# cat <<EOF >~/.directus
# ${DIRECTUS_VERSION}
# EOF

D9_VERSION="12.0.9"
$STD npm install --omit=dev "@wbce-d9/directus9@${D9_VERSION}"
cat <<EOF >~/.d9
${D9_VERSION}
EOF

msg_ok "Installed Directus"

msg_info "Configuring Directus fork d9"
DIRECTUS_KEY=$(openssl rand -hex 32)
DIRECTUS_SECRET=$(openssl rand -hex 32)
DIRECTUS_ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
# cat <<EOF >/opt/directus/.env
cat <<EOF >/opt/d9/.env
HOST="0.0.0.0"
PORT=8055
PUBLIC_URL="http://${LOCAL_IP}:8055"
KEY="${DIRECTUS_KEY}"
SECRET="${DIRECTUS_SECRET}"

DB_CLIENT="pg"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_DATABASE="${DB_DATABASE}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"

CACHE_ENABLED="true"
CACHE_STORE="redis"
CACHE_REDIS="redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}"


# DB_HOST="127.0.0.1"
# DB_PORT=5432
# DB_DATABASE="${PG_DB_NAME}"
# DB_USER="${PG_DB_USER}"
# DB_PASSWORD="${PG_DB_PASS}"

ADMIN_EMAIL="${DIRECTUS_ADMIN_EMAIL}"
ADMIN_PASSWORD="${DIRECTUS_ADMIN_PASSWORD}"

STORAGE_LOCATIONS="local"
STORAGE_LOCAL_DRIVER="local"
# STORAGE_LOCAL_ROOT="/opt/directus/uploads"
# EXTENSIONS_PATH="/opt/directus/extensions"
STORAGE_LOCAL_ROOT="/opt/d9/uploads"
EXTENSIONS_PATH="/opt/d9/extensions"
TELEMETRY=false
EOF
# chmod 640 /opt/directus/.env
chmod 640 /opt/d9/.env
msg_ok "Configured Directus fork d9"

msg_info "Initializing Directus fork d9"
# cd /opt/directus
# $STD /opt/directus/node_modules/.bin/directus bootstrap
cd /opt/d9
$STD /opt/d9/node_modules/.bin/d9 bootstrap
msg_ok "Initialized Directus fork d9"

msg_info "Creating Service"
# cat <<EOF >/etc/systemd/system/directus.service
cat <<EOF >/etc/systemd/system/d9.service
[Unit]
Description=d9
After=network.target
[Service]
Type=simple
User=root
# WorkingDirectory=/opt/directus
# EnvironmentFile=/opt/directus/.env
# ExecStart=/opt/directus/node_modules/.bin/directus start
WorkingDirectory=/opt/d9
EnvironmentFile=/opt/d9/.env
ExecStart=/opt/d9/node_modules/.bin/d9 start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# systemctl enable -q --now directus
systemctl enable -q --now d9
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
