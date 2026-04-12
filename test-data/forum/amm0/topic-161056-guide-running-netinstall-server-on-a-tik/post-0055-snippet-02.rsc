# Source: https://forum.mikrotik.com/t/guide-running-netinstall-server-on-a-tik/161056/55
# Topic: GUIDE: Running Netinstall Server on a Tik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# download qemu-user-static binaries from debian
FROM debian:stable-slim AS qemu
WORKDIR /app
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends qemu-user-static && \
    ls -al /usr/bin && \
    cp $(which qemu-i386-static) .

# make real image using alpine
FROM alpine:latest
WORKDIR /app

## copy qemu x86 static binary from debian layer
COPY --from=qemu /app/qemu-i386-static /app/i386

# we just need make...:
RUN apk add --clean-protected --no-cache make && rm -rf /var/cache/apk/*
COPY Makefile /app/Makefile

## so make is the init
CMD ["make", "service"]
