#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost}"

echo "=== 1. Testing web health endpoint ==="
health_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
echo "GET /health -> HTTP $health_code"
if [[ "$health_code" != "200" ]]; then 
    echo "FAIL: Expected 200 from /health"
    exit 1
fi 

echo ""
echo "=== 2. Testing load balancing across web replicas (10 requests) ==="
for i in $(seq 1 10); do
    resp=$(curl -s "$BASE_URL/health")
    echo "Request $i: $resp"
done

echo ""
echo "=== 3. Testing rate limiting on /api/ask (10 rapid requests) ==="
count_429=0
for i in $(seq 1 10); do
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$BASE_URL/api/ask"\
        -H "Content-Type: application/json" \
        -d '{"question": "test"}')
    echo "Request $i -> HTTP $code"
    if [[ "$code" == "429" ]]; then
        count_429=$((count_429 + 1))
    fi 
done

echo "" 
if (( count_429 > 0 )); then
    echo "PASS: Rate limiting active ($count_429 requests returned 429)"
else
    echo "FAIL: No 429 responses received. Check nginx limit_req settings."
    exit 1
fi