# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/3
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

services:
  web:
    configs:
      - source: 'nginx_conf'
        target: '/etc/nginx/nginx.conf'
        mode: 0755

configs:
  'nginx_conf':
    content: |
      # Inline content here
      server {
        listen 80;
      }
