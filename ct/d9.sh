#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/yocuri/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://directus.com/ | https://github.com/LaWebcapsule/d9

APP="d9"
var_tags="${var_tags:-cms;api;database;headless}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

#  if [[ ! -f /opt/directus/node_modules/.bin/directus ]]; then
#    msg_error "No ${APP} Installation Found!"
#    exit
#  fi

  if [[ ! -f /opt/d9/node_modules/.bin/d9 ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

#  if check_for_gh_release "directus" "directus/directus"; then
  if check_for_gh_release "d9" "LaWebcapsule/d9"; then
    msg_info "Stopping Service"
    systemctl stop d9
    msg_ok "Stopped Service"

    create_backup /opt/d9/.env \
      /opt/d9/uploads \
      /opt/d9/extensions

    ensure_dependencies build-essential

    msg_info "Updating Directus fork d9"
    cd /opt/d9
#    $STD npm install --omit=dev "directus@${CHECK_UPDATE_RELEASE#v}"
    $STD npm install --omit=dev "@wbce-d9/directus9@${CHECK_UPDATE_RELEASE#v}"
    cat <<EOF >~/.d9
${CHECK_UPDATE_RELEASE#v}
EOF
    restore_backup
    msg_ok "Updated Directus fork d9"

    msg_info "Starting Service"
    systemctl start d9
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8055${CL}"
