#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.app.yml}"
SERVICE="web"
NGINX_CONTAINER="lb-nginx"

MIN_REPLICAS=3
MAX_REPLICAS=6
SCALE_UP_THRESHOLD=10
SCALE_DOWN_THRESHOLD=3
CHECK_INTERVAL=15
COOLDOWN=30

last_scale_time=0

echo "[$(date '+%H:%M:%S')] Starting autoscaler for '$SERVICE' (min=$MIN_REPLICAS, max=$MAX_REPLICAS)"

while true; do
    status_output=$(docker exec "$NGINX_CONTAINER" wget -qO- http://127.0.0.1/nginx_status 2>/dev/null || true)
    active_conns=$(echo "$status_output" | awk '/Active connections:/ {print $3}')

    if [[ -z "${active_conns:-}" ]]; then
        echo "[$(date '+%H:%M:%S')] Warning: could not read /nginx_status, retrying.."
        sleep "$CHECK_INTERVAL"
        continue
    fi


    current_replicas=$(docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE" | wc -l | tr -d ' ')
    now=$(date +%s)
    elapsed=$((now - last_scale_time))

    echo "[$(date '+%H:%M:%S')] Active connections: $active_conns | Current replicas: $current_replicas"

    if ((elapsed >= COOLDOWN)); then
        if (( active_conns >= SCALE_UP_THRESHOLD && current_replicas < MAX_REPLICAS)); then
            new_replicas=$((current_replicas + 1))
            echo "[$(date '+%H:%M:%S')] Scaling UP $SERVICE: $current_replicas -> $new_replicas"
            docker compose -f "$COMPOSE_FILE" up -d --scale "$SERVICE=$new_replicas" --no-recreate
            last_scale_time=$now
        elif (( active_conns <= SCALE_DOWN_THRESHOLD && current_replicas > MIN_REPLICAS)); then
            new_replicas=$((current_replicas - 1))
            echo "[$(date '+%H:%M:%S')] Scaling DOWN $SERVICE: $current_replicas -> $new_replicas"
            docker compose -f "$COMPOSE_FILE" up -d --scale "$SERVICE=$new_replicas" --no-recreate
            last_scale_time=$now
        fi
    fi

    sleep "$CHECK_INTERVAL"
done