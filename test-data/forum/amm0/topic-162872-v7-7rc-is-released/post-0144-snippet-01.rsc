# Source: https://forum.mikrotik.com/t/v7-7rc-is-released/162872/144
# Topic: v7.7rc is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

FROM alpine:3.12.0
RUN apk add --no-cache bind
RUN cp /etc/bind/named.conf.recursive /etc/bind/named.conf
EXPOSE 53
CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
