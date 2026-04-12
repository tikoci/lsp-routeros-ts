# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/21
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
   :local interfaceOneName [/tool/snmp-get oid=.1.3.6.1.2.1.2.2.1.2.1 address=127.0.0.1 community=public as-value] 
   :put $interfaceOneName
   :put ($interfaceOneName->"value")
}
# oid=1.3.6.1.2.1.2.2.1.2.1;type=octet-string;value=ether1
# ether1
