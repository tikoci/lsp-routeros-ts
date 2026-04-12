# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/2
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

configs:
  - source: 'nginx_conf'
    target: '/etc/nginx/conf.d/default.conf'
  - source: 'init_script'
    target: '/custom-cont-init.d/init.sh'
    mode: 0755
