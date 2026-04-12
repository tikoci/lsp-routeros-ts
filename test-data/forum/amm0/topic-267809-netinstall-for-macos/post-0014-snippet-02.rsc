# Source: https://forum.mikrotik.com/t/netinstall-for-macos/267809/14
# Topic: NetInstall for MacOS?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ip link set enp0s1 up
 ip addr add 192.168.88.99/24 dev enp0s1
 mkdir /app
 mount /dev/vdb /app
chmod a+x /app/netinstall-cli
/app/netinstall-cli -r -v -b -a 192.168.88.101 *-arm.npk
