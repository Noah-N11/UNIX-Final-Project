#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/project-startup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Common startup begins: $(date) ====="

PACKAGES=(
    docker.io
    lvm2
    curl
    wget
    git
    jq
)

MISSING_PACKAGES=()

for PACKAGE in "${PACKAGES[@]}"; do
    if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
        MISSING_PACKAGES+=("$PACKAGE")
    fi
done

# Install only packages that are missing
if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
    apt-get update
    apt-get install -y "${MISSING_PACKAGES[@]}"
fi

systemctl enable docker
systemctl start docker

docker --version
lvm version

echo "===== Common startup completed: $(date) ====="