# Source: https://forum.mikrotik.com/t/a-very-simple-redirect-to-an-http-page-after-join-wifi/165960/12
# Topic: A very simple redirect (to an http page) after join WiFi
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip dhcp-server option add code=114 name=no-captive-portal value="'urn:ietf:params:capport:unrestricted'"
/ip dhcp-server option sets add name=default options=no-captive-portal
/ip dhcp-server set [find] dhcp-option-set=default
