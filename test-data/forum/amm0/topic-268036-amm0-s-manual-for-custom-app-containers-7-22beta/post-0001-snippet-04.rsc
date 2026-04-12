# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/1
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

name: myapp
services:
  mycontainer:
    image: somerepo.io/myappimage:latest
    configs:
      - source: 'app_config'
        target: '/etc/app/config'
        mode: 0644
configs:
  'app_config':
      content: |
        path /html
        port 80
