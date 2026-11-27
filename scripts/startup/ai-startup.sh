#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/ai-startup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== AI startup begins: $(date) ====="

bash /opt/project-startup/common-startup.sh

DISK_DEVICE="/dev/disk/by-id/google-model-weights" \
VG_NAME="model_vg" \
LV_NAME="model_lv" \
MOUNT_POINT="/models" \
LV_SIZE="100%FREE" \
bash /opt/project-startup/storage-setup.sh

echo "Model storage configured."

# AI inference container deployment will be added later.

echo "===== AI startup completed: $(date) ====="