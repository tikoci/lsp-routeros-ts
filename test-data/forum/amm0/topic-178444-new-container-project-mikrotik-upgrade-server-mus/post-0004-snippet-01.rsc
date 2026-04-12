# Source: https://forum.mikrotik.com/t/new-container-project-mikrotik-upgrade-server-mus/178444/4
# Topic: New container project: "mikrotik.upgrade.server" / "mus"
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

RUN echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/main/' >> /etc/apk/repositories \
    && echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/community' >> /etc/apk/repositories \
    && apk add --no-cache --update --upgrade su-exec ca-certificates
