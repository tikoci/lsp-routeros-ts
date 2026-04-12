# Source: https://forum.mikrotik.com/t/chateau-5g-ax-automatic-cellular-reconnect-on-provider-disconnect/164421/5
# Topic: Chateau 5G ax - Automatic cellular reconnect on provider disconnect
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# check the current-firmware match the RouterOS version 
/system/routerboard/print
# if it doesn't match...
/system/routerboard/upgrade 
# to enable automatic *firmware* upgrade *after* a RouterOS upgrade (so they match)
/system/routerboard/settings/set auto-upgrade=yes
# with auto-upgrade a second reboot is required after the package upgrade
# which you need to do *manually* via /system/reboot to trigger board fw upgrade at startup
# but will cause the board's firmware to match the RouterOS, which you'd likely want
