# Source: https://forum.mikrotik.com/t/wireguard-multi-wan-policy-routing/174145/64
# Topic: WireGuard Multi-WAN Policy Routing
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global pcvlan do={
/interface vlan add interface=$bridge name="$name_VLAN" vlan-id=[:tonum $pvid]
/ip address add interface="$name_VLAN" address="10.0.$pvid.1/24"
/ip pool add name="$name_POOL" ranges="10.0.$pvid.2-10.0.$pvid.254"
/ip dhcp-server add address-pool="$name_POOL" interface="$name_VLAN" name="$name_DHCP" disabled=no
/ip dhcp-server network add address="10.0.$pvid.0/24" dns-server="$dns" gateway="10.0.$pvid.1"
}

$pcvlan name=BLUE pvid=10 bridge=BR1 dns=192.168.0.1
$pcvlan name=GREEN pvid=20 bridge=BR1 dns=192.168.0.1 
$pcvlan name=RED pvid=30 bridge=BR1 dns=192.168.0.1
