# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/17
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/app/add yaml="
name: tikappstore
descr: Serve /app YAML for 'app-store-urls', using busybox httpd
services:
  tikappstore:
    image: docker.io/library/busybox
    command: busybox httpd -f -h /www -v -p 3000 -c /etc/httpd.conf
    ports:
      - 3000:3000/tcp:web
    configs:
      - source: 'tikappstore.yaml'
        target: '/www/tikappstore.yaml'
      - source: 'httpd.conf'
        target: '/etc/httpd.conf'
configs:
  'httpd.conf':
    content: |
      .yaml:text/yaml
  'tikappstore.yaml':
    content: |
      -
        name: bind9
        services:
          bind9:
            ports:
                - 53:53/udp:dns
                - 53:53/tcp:dns
            image: docker.io/internetsystemsconsortium/bind9:9.18
      -
        name: unbound
        services:
          unbound:
            ports:
                - 53:53/tcp:dns
                - 53:53/udp:dns
            image: docker.io/klutchell/unbound:latest
"
