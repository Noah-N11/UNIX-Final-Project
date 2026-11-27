#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/database-startup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Database startup begins: $(date) ====="

bash /opt/project-startup/common-startup.sh

DISK_DEVICE="/dev/disk/by-id/google-db-data" \
VG_NAME="db_vg" \
LV_NAME="db_lv" \
MOUNT_POINT="/data/db" \
LV_SIZE="100%FREE" \
bash /opt/project-startup/storage-setup.sh

echo "Database storage configured."

# Database container deployment will be added later.

echo "===== Database startup completed: $(date) ====="