# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/4
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# yaml-language-server: $schema=https://tikoci.github.io/restraml/routeros-app-yaml-schema.latest.json
name: amm0-note
descr: Use a YAML comment at top of file to load a schema
services:
 example:
   image: docker.io/library/alpine
