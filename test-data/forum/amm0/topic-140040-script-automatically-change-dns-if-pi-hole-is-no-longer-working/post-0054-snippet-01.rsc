# Source: https://forum.mikrotik.com/t/script-automatically-change-dns-if-pi-hole-is-no-longer-working/140040/54
# Topic: [Script] Automatically change DNS if Pi-hole is no longer working
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global primary 172.17.0.2
:global backup 9.9.9.9
:global lookup www.mikrotik.com
/tool netwatch add type=dns dns-server=$primary record-type=A host=$lookup \
     down-script="/ip/dns/set server=$backup" \
     up-script="/ip/dns/set server=$primary"
