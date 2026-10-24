#!/bin/sh
set -e

# ─── 环境变量（全部可在 Railway Variables 面板配置） ─────────
PROXY_USER="${PROXY_USER:-admin}"
PROXY_PASS="${PROXY_PASS:-changeme}"
PROXY_PORT="${PROXY_PORT:-1080}"
HEALTH_PORT="${PORT:-3000}"          # Railway 自动注入 PORT

# ─── 对密码中的 URL 特殊字符进行编码 ────────────────────────
#     解决 # @ : / ? & = 空格 等字符导致 GOST URL 解析失败的问题
ENCODED_PASS=$(printf '%s' "$PROXY_PASS" | sed \
    -e 's/%/%25/g'  \
    -e 's/#/%23/g'  \
    -e 's/@/%40/g'  \
    -e 's/:/%3A/g'  \
    -e 's/\//%2F/g' \
    -e 's/?/%3F/g'  \
    -e 's/&/%26/g'  \
    -e 's/=/%3D/g'  \
    -e 's/ /%20/g')

# ─── 生成 GOST 配置文件 ─────────────────────────────────────
#     不指定 scheme → auto 模式 → 同一端口自动识别 HTTP / SOCKS5
cat > /tmp/gost.json << EOF
{
    "Retries": 3,
    "ServeNodes": [
        "${PROXY_USER}:${ENCODED_PASS}@:${PROXY_PORT}"
    ]
}
EOF

# ─── 启动信息 ───────────────────────────────────────────────
echo "=========================================="
echo "  GOST Proxy Service"
echo "=========================================="
echo "  Proxy  : :${PROXY_PORT}  (auto: HTTP + SOCKS5)"
echo "  Health : :${HEALTH_PORT} (HTTP)"
echo "  User   : ${PROXY_USER}"
echo "=========================================="

# ─── 导出健康检查所需的端口号 ───────────────────────────────
export CHECK_PORT="$PROXY_PORT"

# ─── 启动健康检查 HTTP 服务（后台） ─────────────────────────
socat TCP-LISTEN:"${HEALTH_PORT}",reuseaddr,fork EXEC:/health.sh &
echo "[INFO] Health check listening on :${HEALTH_PORT}"

# ─── 启动 GOST 代理（前台，PID 1，接管信号） ───────────────
exec gost -C /tmp/gost.json
