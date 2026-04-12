# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/50
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# get SSL cert for RouterOS, somehow, one way:
/certificate/enable-ssl-certificate

# enable global reverse-proxy
/ip/service/set reverse-proxy disabled=no certificate=[/certificate/get [find private-key=yes !expired] name]

# add proxy rules to based on SNI...
# ... and this one has no CLI - use WinBox
#    and apparently if SNI is blank it matches all requests
