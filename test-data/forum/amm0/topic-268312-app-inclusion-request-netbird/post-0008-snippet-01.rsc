# Source: https://forum.mikrotik.com/t/app-inclusion-request-netbird/268312/8
# Topic: App inclusion request - Netbird
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

-
  name: netbird-client
  services:
    netbird-client:
      environment:
        NB_SETUP_KEY: MUST_SET_FROM_NETBIRD
        NB_DISABLE_CUSTOM_ROUTING: 'true'
        NB_USE_LEGACY_ROUTING: 'true'
      volumes:
        - netbird-client:/var/lib/netbird
      image: docker.io/netbirdio/netbird:latest
