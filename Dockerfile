FROM alpine:3.19

LABEL description="GOST Proxy with Health Check for Railway"

ARG GOST_VERSION=2.11.5

# socat: 健康检查 HTTP 服务器
# ca-certificates: HTTPS 代理所需的根证书
RUN apk add --no-cache socat ca-certificates \
    && wget -qO /tmp/gost.gz \
       "https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost-linux-amd64-${GOST_VERSION}.gz" \
    && gunzip /tmp/gost.gz \
    && mv /tmp/gost /usr/local/bin/gost \
    && chmod +x /usr/local/bin/gost \
    && rm -rf /tmp/* /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY health.sh     /health.sh
RUN chmod +x /entrypoint.sh /health.sh

ENTRYPOINT ["/entrypoint.sh"]
