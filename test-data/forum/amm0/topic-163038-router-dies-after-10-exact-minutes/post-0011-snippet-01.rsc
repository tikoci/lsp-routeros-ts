# Source: https://forum.mikrotik.com/t/router-dies-after-10-exact-minutes/163038/11
# Topic: Router "dies" after 10 exact minutes
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# dec/21/2022 20:48:28 by RouterOS 6.48.6
# software id = 
#
# model = RB1100x4
# serial number = 
/interface bridge
add name=bridgeLAN
/interface ethernet
set [ find default-name=ether1 ] name=ether1-WAN1
set [ find default-name=ether2 ] name=ether2-switch-poe200
set [ find default-name=ether3 ] name=ether3-WAN2-Mati
set [ find default-name=ether4 ] name=ether4-switch-poe201
set [ find default-name=ether5 ] name=ether5-WAN3-Pachi
set [ find default-name=ether12 ] name=ether12-WAN5-Ger
set [ find default-name=ether13 ] name=ether13-WAN4-Benja
/interface vlan
add interface=ether1-WAN1 name=vlan_wan1_a vlan-id=101
add interface=ether1-WAN1 name=vlan_wan1_b vlan-id=102
/interface ethernet switch port
set 0 default-vlan-id=0
set 1 default-vlan-id=0
set 2 default-vlan-id=0
set 3 default-vlan-id=0
set 4 default-vlan-id=0
set 5 default-vlan-id=0
set 6 default-vlan-id=0
set 7 default-vlan-id=0
set 8 default-vlan-id=0
set 9 default-vlan-id=0
set 10 default-vlan-id=0
set 11 default-vlan-id=0
set 12 default-vlan-id=0
set 13 default-vlan-id=0
set 14 default-vlan-id=0
set 15 default-vlan-id=0
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp ranges=\
    10.10.200.99-10.10.200.100,10.10.200.108/30,10.10.200.112/30
/ip dhcp-server
add address-pool=dhcp disabled=no interface=bridgeLAN name=servidorDHCP-WLAN
/queue simple

[erased queues]

add max-limit=768k/10M name="RESTO RED 110" target=10.10.110.0/24
add max-limit=10M/10M name="RESTO RED 100" target=10.10.100.0/24
add max-limit=1M/5M name="RESTO RED 200" target=10.10.200.0/24
/routing bgp instance
set default as=55 router-id=192.168.100.200
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp"
/dude
set data-directory=disk1/dude enabled=yes
/interface bridge port
add bridge=bridgeLAN interface=ether2-switch-poe200
add bridge=bridgeLAN disabled=yes interface=ether3-WAN2-Mati
add bridge=bridgeLAN interface=ether4-switch-poe201
add bridge=bridgeLAN disabled=yes interface=ether5-WAN3-Pachi
add bridge=bridgeLAN interface=ether6
add bridge=bridgeLAN interface=ether7
add bridge=bridgeLAN interface=ether8
add bridge=bridgeLAN interface=ether9
add bridge=bridgeLAN interface=ether10
add bridge=bridgeLAN disabled=yes interface=ether12-WAN5-Ger
/ip address
add address=10.10.100.1/24 comment="IP Lan Equipos" interface=bridgeLAN \
    network=10.10.100.0
add address=10.10.200.1/24 comment="IP Lan Clientes AC Seg1" interface=\
    bridgeLAN network=10.10.200.0
add address=192.168.100.200/24 comment="lan 750" interface=ether1-WAN1 \
    network=192.168.100.0
add address=192.168.15.200/24 interface=ether13-WAN4-Benja network=\
    192.168.15.0
add address=10.10.110.1/24 comment="IP Lan Clientes LTU Seg1" interface=\
    bridgeLAN network=10.10.110.0
add address=192.168.1.15/24 interface=ether5-WAN3-Pachi network=192.168.1.0
add address=10.10.105.1/29 comment="Ptps Wan3" interface=ether5-WAN3-Pachi \
    network=10.10.105.0
add address=10.10.105.9/29 comment="Ptps Wan5" interface=ether12-WAN5-Ger \
    network=10.10.105.8
add address=192.168.200.110/24 comment="Wan2 del 750" interface=vlan_wan1_b \
    network=192.168.200.0
add address=192.168.80.120/24 comment="Wan1 del 750" interface=vlan_wan1_a \
    network=192.168.80.0
/ip dhcp-client
add default-route-distance=3 disabled=no interface=ether3-WAN2-Mati \
    use-peer-dns=no use-peer-ntp=no
add default-route-distance=2 disabled=no interface=ether5-WAN3-Pachi \
    use-peer-dns=no use-peer-ntp=no
add default-route-distance=3 disabled=no interface=ether12-WAN5-Ger \
    use-peer-dns=no use-peer-ntp=no
/ip dhcp-server lease
add address=10.10.200.100 client-id=1:c0:25:67:99:68:43 mac-address=\
    C0:25:67:99:68:43 server=servidorDHCP-WLAN
add address=10.10.200.99 client-id=1:c0:25:67:99:67:a3 mac-address=\
    C0:25:67:99:67:A3 server=servidorDHCP-WLAN
add address=10.10.200.110 client-id=1:c0:25:67:b8:24:bc mac-address=\
    C0:25:67:B8:24:BC server=servidorDHCP-WLAN
add address=10.10.200.109 client-id=1:0:5f:67:b4:70:9 mac-address=\
    00:5F:67:B4:70:09 server=servidorDHCP-WLAN
add address=10.10.200.111 client-id=1:c0:25:2f:fe:5f:ff mac-address=\
    C0:25:2F:FE:5F:FF server=servidorDHCP-WLAN
add address=10.10.200.108 client-id=1:c0:25:2f:fe:6a:35 mac-address=\
    C0:25:2F:FE:6A:35 server=servidorDHCP-WLAN
add address=10.10.200.113 client-id=1:c0:25:67:c8:71:5c mac-address=\
    C0:25:67:C8:71:5C server=servidorDHCP-WLAN
add address=10.10.200.114 client-id=1:c0:25:2f:fe:6a:5d mac-address=\
    C0:25:2F:FE:6A:5D server=servidorDHCP-WLAN
/ip dhcp-server network
add address=10.10.100.0/24 gateway=10.10.100.1 netmask=24
add address=10.10.200.0/24 dns-server=10.10.200.1,8.8.8.8,8.8.4.4 gateway=\
    10.10.200.1
/ip dns
set allow-remote-requests=yes cache-size=8096KiB servers=8.8.8.8,8.8.4.4
/ip firewall address-list

[erased address-list]

/ip firewall filter
add action=accept chain=input comment="NTP Admitir solo a time.google.com" \
    dst-port=123 protocol=tcp src-address=216.239.35.12
add action=accept chain=input dst-port=123 protocol=udp src-address=\
    216.239.35.12
add action=accept chain=input comment="Dejar pasar Windors" src-address=\
    192.168.2.100
add action=accept chain=forward comment="Deja Pasar Windors" src-address=\
    192.168.2.100
add action=drop chain=input dst-port=123 protocol=udp
add action=accept chain=input comment=ucrm_accept_input src-address=\
    192.168.2.197
add action=accept chain=forward comment=ucrm_accept_forward src-address=\
    192.168.2.197
add action=jump chain=forward comment=ucrm_forward_first jump-target=\
    ucrm_forward_first
add action=jump chain=forward comment=ucrm_forward_general jump-target=\
    ucrm_forward_general
add action=jump chain=forward comment=ucrm_forward_drop jump-target=\
    ucrm_forward_drop
add action=accept chain=ucrm_forward_general comment=\
    ucrm_blocked_users_allow_dns dst-port=53 protocol=udp src-address-list=\
    BLOCKED_USERS
add action=drop chain=ucrm_forward_drop comment=ucrm_blocked_users_drop \
    dst-address=!192.168.2.197 src-address-list=BLOCKED_USERS
add action=accept chain=input comment=ucrm_suspend_accept_input src-address=\
    192.168.2.197
add action=accept chain=forward comment=ucrm_suspend_accept_forward \
    src-address=192.168.2.197
add action=jump chain=forward comment=ucrm_suspend_forward_first jump-target=\
    ucrm_suspend_forward_first
add action=jump chain=forward comment=ucrm_suspend_forward_general \
    jump-target=ucrm_suspend_forward_general
add action=jump chain=forward comment=ucrm_suspend_forward_drop jump-target=\
    ucrm_suspend_forward_drop
add action=accept chain=ucrm_suspend_forward_general comment=\
    ucrm_suspend_blocked_users_allow_dns dst-port=53 protocol=udp \
    src-address-list=BLOCKED_USERS_Synced
add action=drop chain=ucrm_suspend_forward_drop comment=\
    ucrm_suspend_blocked_users_drop dst-address=!192.168.2.197 \
    src-address-list=BLOCKED_USERS_Synced
/ip firewall mangle
add action=accept chain=prerouting dst-address=192.168.2.197 in-interface=\
    bridgeLAN
add action=accept chain=prerouting dst-address=192.168.2.100 in-interface=\
    bridgeLAN
add action=accept chain=prerouting comment="Bypass al unms" disabled=yes \
    dst-address=192.168.2.0/24
add action=accept chain=prerouting comment="Bypass al unms" disabled=yes \
    src-address=192.168.2.0/24
add action=accept chain=prerouting comment="Conexiones Locales" dst-address=\
    192.168.100.0/24
add action=accept chain=prerouting comment="Conexiones Locales" dst-address=\
    192.168.80.0/24
add action=accept chain=prerouting comment=\
    "Acepta Las Redes de los proveedores" dst-address=192.168.50.0/24
add action=accept chain=prerouting comment=\
    "Acepta Las Redes de los proveedores VLAN 750" dst-address=\
    192.168.200.0/24
add action=accept chain=prerouting comment=\
    "Acepta Las Redes de los proveedores" dst-address=192.168.1.0/24
add action=accept chain=prerouting comment=\
    "Acepta Las Redes de los proveedores" dst-address=192.168.15.0/24
add action=accept chain=prerouting comment=\
    "Acepta Las Redes de los proveedores" dst-address=192.168.0.0/24
add action=mark-connection chain=prerouting comment=\
    "Conecciones entrantes de los ISP" in-interface=vlan_wan1_a \
    new-connection-mark=isp1_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=ether3-WAN2-Mati \
    new-connection-mark=isp2_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=ether5-WAN3-Pachi \
    new-connection-mark=isp3_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=ether13-WAN4-Benja \
    new-connection-mark=isp4_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=ether12-WAN5-Ger \
    new-connection-mark=isp5_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=vlan_wan1_b \
    new-connection-mark=isp6_conn passthrough=yes
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/0" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp1_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/0
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/1" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp2_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/1
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/2" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp3_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/2
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/3" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp4_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/3
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/3" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp5_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/4
add action=mark-connection chain=prerouting comment=\
    "Balanceo de clientes 4/3" dst-address-type=!local in-interface=bridgeLAN \
    new-connection-mark=isp6_conn passthrough=yes per-connection-classifier=\
    both-addresses:6/5
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP1" connection-mark=isp1_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp1 passthrough=yes
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP2" connection-mark=isp2_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp2 passthrough=yes
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP3" connection-mark=isp3_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp3 passthrough=yes
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP4" connection-mark=isp4_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp4 passthrough=yes
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP5" connection-mark=isp5_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp5 passthrough=yes
add action=mark-routing chain=prerouting comment=\
    "Enrrutado de los paquetes marcados al ISP6" connection-mark=isp6_conn \
    in-interface=bridgeLAN new-routing-mark=to_isp6 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp1_conn new-routing-mark=to_isp1 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp2_conn new-routing-mark=to_isp2 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp3_conn new-routing-mark=to_isp3 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp4_conn new-routing-mark=to_isp4 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp5_conn new-routing-mark=to_isp5 passthrough=yes
add action=mark-routing chain=output comment="Salidas del Balanceador" \
    connection-mark=isp6_conn new-routing-mark=to_isp5 passthrough=yes
add action=accept chain=prerouting disabled=yes dst-address=192.168.50.0/24 \
    in-interface=bridgeLAN
add action=accept chain=prerouting disabled=yes dst-address=192.168.1.0/24 \
    in-interface=bridgeLAN
add action=accept chain=prerouting disabled=yes dst-address=192.168.15.0/24 \
    in-interface=bridgeLAN
add action=mark-connection chain=prerouting comment="Balanceo de los ISP" \
    connection-mark=no-mark disabled=yes dst-address-type=!local \
    in-interface=bridgeLAN new-connection-mark=WAN1_conn passthrough=yes \
    per-connection-classifier=both-addresses:6/0
add action=mark-connection chain=prerouting connection-mark=no-mark disabled=\
    yes dst-address-type=!local in-interface=bridgeLAN new-connection-mark=\
    WAN1_conn passthrough=yes per-connection-classifier=both-addresses:6/1
add action=mark-connection chain=prerouting connection-mark=no-mark disabled=\
    yes dst-address-type=!local in-interface=bridgeLAN new-connection-mark=\
    WAN2_conn passthrough=yes per-connection-classifier=both-addresses:6/2
add action=mark-connection chain=prerouting connection-mark=no-mark disabled=\
    yes dst-address-type=!local in-interface=bridgeLAN new-connection-mark=\
    WAN2_conn passthrough=yes per-connection-classifier=both-addresses:6/3
add action=mark-connection chain=prerouting connection-mark=no-mark disabled=\
    yes dst-address-type=!local in-interface=bridgeLAN new-connection-mark=\
    WAN4_conn passthrough=yes per-connection-classifier=both-addresses:6/4
add action=mark-connection chain=prerouting connection-mark=no-mark disabled=\
    yes dst-address-type=!local in-interface=bridgeLAN new-connection-mark=\
    WAN4_conn passthrough=yes per-connection-classifier=both-addresses:6/5
add action=mark-routing chain=prerouting comment="Definir Rutas" \
    connection-mark=WAN1_conn disabled=yes in-interface=bridgeLAN \
    new-routing-mark=to_WAN1 passthrough=no
add action=mark-routing chain=prerouting connection-mark=WAN2_conn disabled=\
    yes in-interface=bridgeLAN new-routing-mark=to_WAN2 passthrough=no
add action=mark-routing chain=prerouting connection-mark=WAN3_conn disabled=\
    yes in-interface=bridgeLAN new-routing-mark=to_WAN3 passthrough=no
add action=mark-routing chain=prerouting connection-mark=WAN4_conn disabled=\
    yes in-interface=bridgeLAN new-routing-mark=to_WAN4 passthrough=no
add action=mark-routing chain=output comment=\
    "Definir la salida de las conexiones" connection-mark=WAN1_conn disabled=\
    yes new-routing-mark=to_WAN1 passthrough=no
add action=mark-routing chain=output connection-mark=WAN2_conn disabled=yes \
    new-routing-mark=to_WAN2 passthrough=no
add action=mark-routing chain=output connection-mark=WAN3_conn disabled=yes \
    new-routing-mark=to_WAN3 passthrough=no
add action=mark-routing chain=output connection-mark=WAN4_conn disabled=yes \
    new-routing-mark=to_WAN4 passthrough=no
/ip firewall nat
add action=dst-nat chain=dstnat comment="Captura DDNS puntofutura" disabled=\
    yes dst-address=181.166.165.151 dst-port=443 protocol=tcp to-addresses=\
    192.168.2.197 to-ports=443
add action=redirect chain=dstnat comment="Captura DNS" dst-port=53 protocol=\
    udp
add action=accept chain=srcnat disabled=yes dst-address=192.168.2.0/24 \
    out-interface=ether1-WAN1
add action=masquerade chain=srcnat comment="Nateo de la VLAN1a" \
    out-interface=vlan_wan1_a
add action=masquerade chain=srcnat comment="Nateo de la VLAN1b" \
    out-interface=vlan_wan1_b
add action=masquerade chain=srcnat disabled=yes out-interface=ether1-WAN1 \
    src-address=10.10.200.0/24
add action=masquerade chain=srcnat disabled=yes out-interface=ether1-WAN1 \
    src-address=10.10.110.0/24
add action=masquerade chain=srcnat out-interface=ether3-WAN2-Mati
add action=masquerade chain=srcnat out-interface=ether5-WAN3-Pachi
add action=masquerade chain=srcnat out-interface=ether13-WAN4-Benja
add action=masquerade chain=srcnat out-interface=ether12-WAN5-Ger
add action=jump chain=dstnat comment=ucrm_first_dstnat jump-target=\
    ucrm_first_dstnat
add action=jump chain=dstnat comment=ucrm_general_dstnat jump-target=\
    ucrm_general_dstnat
add action=jump chain=dstnat comment=ucrm_last_dstnat jump-target=\
    ucrm_last_dstnat
add action=jump chain=srcnat comment=ucrm_first_srcnat jump-target=\
    ucrm_first_srcnat
add action=jump chain=srcnat comment=ucrm_general_srcnat jump-target=\
    ucrm_general_srcnat
add action=jump chain=srcnat comment=ucrm_range_srcnat jump-target=\
    ucrm_range_srcnat
add action=jump chain=srcnat comment=ucrm_last_srcnat jump-target=\
    ucrm_last_srcnat
add action=dst-nat chain=ucrm_first_dstnat comment=ucrm_blocked_user_redirect \
    dst-port=80 protocol=tcp src-address-list=BLOCKED_USERS to-addresses=\
    192.168.2.197 to-ports=80
add action=jump chain=dstnat comment=ucrm_suspend_first_dstnat jump-target=\
    ucrm_suspend_first_dstnat
add action=jump chain=dstnat comment=ucrm_suspend_general_dstnat jump-target=\
    ucrm_suspend_general_dstnat
add action=jump chain=dstnat comment=ucrm_suspend_last_dstnat jump-target=\
    ucrm_suspend_last_dstnat
add action=jump chain=srcnat comment=ucrm_suspend_first_srcnat jump-target=\
    ucrm_suspend_first_srcnat
add action=jump chain=srcnat comment=ucrm_suspend_general_srcnat jump-target=\
    ucrm_suspend_general_srcnat
add action=jump chain=srcnat comment=ucrm_suspend_range_srcnat jump-target=\
    ucrm_suspend_range_srcnat
add action=jump chain=srcnat comment=ucrm_suspend_last_srcnat jump-target=\
    ucrm_suspend_last_srcnat
add action=dst-nat chain=ucrm_suspend_first_dstnat comment=\
    ucrm_suspend_blocked_user_redirect dst-port=80 protocol=tcp \
    src-address-list=BLOCKED_USERS_Synced to-addresses=192.168.2.197 \
    to-ports=80
/ip proxy
set enabled=yes port=11201
/ip route
add check-gateway=ping comment="To ISP1 Vlan1a 750" distance=1 gateway=\
    192.168.80.1 routing-mark=to_isp1
add check-gateway=ping comment="To ISP2" distance=1 gateway=192.168.50.1 \
    routing-mark=to_isp2
add check-gateway=ping comment="To ISP3" distance=1 gateway=192.168.1.1 \
    routing-mark=to_isp3
add check-gateway=ping comment="To ISP4" distance=1 gateway=192.168.15.1 \
    routing-mark=to_isp4
add check-gateway=ping comment="To ISP5" distance=1 gateway=192.168.0.1 \
    routing-mark=to_isp5
add check-gateway=ping comment="To ISP6 Vlan1b 750" distance=1 gateway=\
    192.168.200.1 routing-mark=to_isp6
add check-gateway=ping disabled=yes distance=2 gateway=192.168.100.1 \
    routing-mark=to_WAN1
add check-gateway=ping disabled=yes distance=2 gateway=192.168.50.1 \
    routing-mark=to_WAN2
add check-gateway=ping disabled=yes distance=2 gateway=192.168.1.1 \
    routing-mark=to_WAN3
add check-gateway=ping disabled=yes distance=2 gateway=192.168.15.1 \
    routing-mark=to_WAN4
add comment="Main Wan3 (cooperativa)" distance=1 gateway=192.168.1.1
add check-gateway=ping comment="Main 750" distance=2 gateway=192.168.100.1
add disabled=yes distance=1 gateway=192.168.0.1
add comment="Static Route para el otro router" disabled=yes distance=1 \
    dst-address=192.168.2.0/24 gateway=192.168.100.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set winbox port=8292
set api-ssl disabled=yes
/ip traffic-flow
set enabled=yes
/ip traffic-flow target
add dst-address=192.168.2.197
/routing bgp network
add network=10.10.110.0/24
add network=10.10.200.0/24
add network=10.10.105.0/29
add network=10.10.105.8/29
add comment=Equipos network=10.10.200.244/32
/routing bgp peer
add name=750 remote-address=192.168.100.1 remote-as=50
/snmp
set enabled=yes
/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system identity
set name=MK2-RS
/system ntp client
set enabled=yes primary-ntp=216.239.35.12
/system scheduler
add interval=1d name=backup_binary on-event="/sys script run backup_binary" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=aug/03/2020 start-time=03:30:00
add interval=1d name=backup_export on-event="/sys script run backup_export" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=aug/03/2020 start-time=03:30:00
/system script
add dont-require-permissions=no name=backup_binary owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    system backup save name=([/system identity get name] . \"-\" . \\\
    \n[:pick [/system clock get date] 7 11] . [:pick [/system clock get date] \
    0 3] . [:pick [/system clock get date] 4 6]); \\\
    \n/tool e-mail send to=\"[erased]\" subject=([/system identity \
    get name] . \"_BACKUP//\" . \\\
    \n[/system clock get date]) file=([/system identity get name] . \"-\" . [:\
    pick [/system clock get date] 7 11] . \\\
    \n[:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4\
    \_6] . \".backup\"); :delay 10; \\\
    \n/file rem [/file find name=([/system identity get name] . \"-\" . [:pick\
    \_[/system clock get date] 7 11] . \\\
    \n[:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4\
    \_6] . \".backup\")]; \\\
    \n:log info (\"System Backup emailed at \" . [/sys cl get time] . \" \" . \
    [/sys cl get date])"
add dont-require-permissions=no name=backup_export owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    export file=([/system identity get name] . \"-\" . \\\
    \n[:pick [/system clock get date] 7 11] . [:pick [/system clock get date] \
    0 3] . [:pick [/system clock get date] 4 6]); :delay 2; \\\
    \n/tool e-mail send to=\"[erased]\" subject=([/system identity \
    get name] . \"_BACKUP//\" . \\\
    \n[/system clock get date]) file=([/system identity get name] . \"-\" . [:\
    pick [/system clock get date] 7 11] . \\\
    \n[:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4\
    \_6] . \".rsc\"); :delay 10; \\\
    \n/file rem [/file find name=([/system identity get name] . \"-\" . [:pick\
    \_[/system clock get date] 7 11] . \\\
    \n[:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4\
    \_6] . \".rsc\")]; \\\
    \n:log info (\"System Backup emailed at \" . [/sys cl get time] . \" \" . \
    [/sys cl get date])"
/system watchdog
set automatic-supout=no watchdog-timer=no
/tool graphing interface
add interface=bridgeLAN
/tool graphing resource
add
