# Source: https://forum.mikrotik.com/t/odd-sip-registration-issue-on-chr-7-7-today/164116/2
# Topic: Odd SIP registration issue on CHR 7.7 today
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/firewall/service-port/print detail where name~"sip"

Flags: X - disabled, I - invalid 
 4   name="sip" ports=5060,5061 sip-direct-media=yes sip-timeout=1h
