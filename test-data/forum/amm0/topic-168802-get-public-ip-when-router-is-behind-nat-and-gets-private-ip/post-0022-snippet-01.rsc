# Source: https://forum.mikrotik.com/t/get-public-ip-when-router-is-behind-nat-and-gets-private-ip/168802/22
# Topic: Get public IP when router is behind NAT and gets private IP
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local myPublic [/ip cloud get public-address]
    :put $myPublic
}
