# Source: https://forum.mikrotik.com/t/hap-ax3-supported-containers-docker/169029/4
# Topic: hAP ax3 - supported containers / docker
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

FROM alpine:latest
RUN apk add --no-cache bind
RUN cp /etc/bind/named.conf.recursive /etc/bind/named.conf
CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
