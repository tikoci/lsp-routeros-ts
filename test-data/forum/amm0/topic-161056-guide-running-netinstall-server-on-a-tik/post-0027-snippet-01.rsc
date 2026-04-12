# Source: https://forum.mikrotik.com/t/guide-running-netinstall-server-on-a-tik/161056/27
# Topic: GUIDE: Running Netinstall Server on a Tik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

if [[ $(uname -m) =~ (i[1-6]86|amd64) ]]; then
    exec /app/netinstall-cli $NETINSTALL_ARGS "-a" $NETINSTALL_ADDR /app/images/$NETINSTALL_NPK
else
    exec /app/qemu-i386-static /app/netinstall-cli $NETINSTALL_ARGS "-a" $NETINSTALL_ADDR /app/images/$NETINSTALL_NPK
fi
