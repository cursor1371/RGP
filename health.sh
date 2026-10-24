#!/bin/sh

# ─── 读取并丢弃 HTTP 请求头（符合 HTTP 协议规范） ──────────
while read -r line; do
    line=$(printf '%s' "$line" | tr -d '\r\n')
    [ -z "$line" ] && break
done

# ─── 探测 GOST 代理端口是否存活 ────────────────────────────
CHECK_PORT="${CHECK_PORT:-1080}"
SERVICE_NAME="${SERVICE_NAME:-RGP}"

if nc -z 127.0.0.1 "$CHECK_PORT" 2>/dev/null; then
    BODY="{\"status\":\"healthy\",\"service\":\"${SERVICE_NAME}\"}"
    printf "HTTP/1.1 200 OK\r\n"
else
    BODY="{\"status\":\"unhealthy\",\"service\":\"${SERVICE_NAME}\"}"
    printf "HTTP/1.1 503 Service Unavailable\r\n"
fi

printf "Content-Type: application/json\r\n"
printf "Content-Length: %d\r\n" "${#BODY}"
printf "Connection: close\r\n"
printf "\r\n"
printf "%s" "$BODY"
