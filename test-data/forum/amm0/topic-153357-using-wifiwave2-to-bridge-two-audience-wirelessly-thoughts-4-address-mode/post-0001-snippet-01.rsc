# Source: https://forum.mikrotik.com/t/using-wifiwave2-to-bridge-two-audience-wirelessly-thoughts-4-address-mode/153357/1
# Topic: Using WifiWave2 to bridge two Audience wirelessly, thoughts? == 4-address mode
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# nov/14/2021 10:31:11 by RouterOS 7.1rc6
# software id = AC0K-0Z8R
# model = RBD25GR-5HPacQD2HPnD
/interface bridge
add name=bridge1
/interface lte
# SIM not present
set [ find ] allow-roaming=no name=lte1
/interface eoip
add comment="tunnel using non-bridged \"mesh\" wifi interface to another Audie\
    nce in station mode, so bridge1 is connect between an in-range peer" \
    local-address=192.168.71.1 mac-address=02:23:06:EB:8C:53 mtu=1500 name=\
    eoip-wifimesh remote-address=192.168.71.72 tunnel-id=71
/interface vrrp
add comment="use VRRP on bridge1 so only one default route for \"mesh bridge\"\
    \_(if peer cannot connect or is off, each unit still operates independentl\
    y)" interface=bridge1 name=vrrp-bridge1 priority=99
/interface list
add name=WAN
add name=LAN
/interface wifiwave2 security
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=mobileskyfi
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=noproblem
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=ztsecure
/interface wifiwave2 configuration
add channel.skip-dfs-channels=all .width=20mhz country="United States3" name=\
    M171 security=mobileskyfi ssid=M171
add channel.skip-dfs-channels=all country="United States3" name=SkyTower \
    security=noproblem ssid=SkyTower
add channel.skip-dfs-channels=all country="United States3" hide-ssid=yes \
    name=SkyBridge security=ztsecure ssid=SkyBridge+SkyTower
/interface wifiwave2
set [ find default-name=wifi1 ] configuration=M171 configuration.mode=ap \
    disabled=no name=wifi-2.4Ghz
set [ find default-name=wifi2 ] configuration=SkyTower configuration.mode=ap \
    disabled=no name=wifi-5Ghz
set [ find default-name=wifi3 ] arp-timeout=30s configuration=SkyBridge \
    configuration.mode=ap disabled=no l2mtu=1600 mtu=1550 name=wifi-MeshAP
/ip pool
add name=dhcp ranges=192.168.0.201-192.168.0.249
add name=dhcp_pool1 ranges=192.168.71.201-192.168.71.249
/ip dhcp-server
add address-pool=dhcp interface=vrrp-bridge1 lease-time=1h name=dhcp1
add address-pool=dhcp_pool1 interface=wifi-MeshAP name=dhcp2
/port
set 0 name=usb1
/interface ppp-client
add apn=internet name=ppp-out1 port=usb1
/zerotier
set zt1 comment="ZeroTier Central controller - https://my.zerotier.com/" \
    identity="xxx" name=zt1 \
    port=9993
/zerotier interface
add instance=zt1 mac-address=2E:D1:09:E9:A3:35 name=zerotier1 network=\
   xxx
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=wifi-2.4Ghz
add bridge=bridge1 interface=wifi-5Ghz
add bridge=bridge1 interface=eoip-wifimesh
/ipv6 settings
set disable-ipv6=yes
/interface list member
add interface=lte1 list=WAN
add interface=ether1 list=LAN
add interface=ether2 list=LAN
add interface=wifi-2.4Ghz list=LAN
add interface=wifi-MeshAP list=LAN
add interface=wifi-5Ghz list=LAN
add interface=bridge1 list=LAN
add interface=vrrp-bridge1 list=LAN
add interface=eoip-wifimesh list=LAN
add interface=ppp-out1 list=WAN
add interface=zerotier1 list=LAN
/ip address
add address=192.168.0.71/24 interface=bridge1 network=192.168.0.0
add address=192.168.0.1 interface=vrrp-bridge1 network=192.168.0.1
add address=192.168.71.1/24 interface=wifi-MeshAP network=192.168.71.0
/ip cloud
set ddns-enabled=yes
/ip dhcp-server lease
add address=192.168.71.72 client-id=1:c4:ad:34:86:57:ae comment=\
    "for M172-Rizi station (routing & EoIP need fixed IP address)" \
    mac-address=C4:AD:34:86:57:AE server=dhcp2
/ip dhcp-server network
add address=192.168.0.0/24 comment="bridge1 LAN (via VRRP)" dns-server=\
    208.67.222.222,8.8.4.4 gateway=192.168.0.1 netmask=24
add address=192.168.71.0/24 comment=\
    "PtMP Hub network for using \"mesh\" wifi interface without bridging" \
    dns-server=208.67.222.222,8.8.4.4 gateway=192.168.71.1
/ip dns
set servers=208.67.222.222,8.8.4.4
/ip firewall filter
add action=accept chain=forward comment="allow zerotier" in-interface=\
    zerotier1
add action=accept chain=input comment="allow zerotier" in-interface=zerotier1
add action=accept chain=input protocol=icmp
add action=accept chain=input connection-state=established
add action=accept chain=input connection-state=related
add action=accept chain=input comment="always allow winbox" connection-state=\
    related dst-port=8291 protocol=tcp
add action=drop chain=input in-interface-list=!LAN
add action=drop chain=forward comment=\
    "invalid connections should not go out to LTE" connection-state=invalid \
    log=yes log-prefix=lteinvalid out-interface=lte1
add action=drop chain=output comment=\
    "invalid connections should not go out to LTE" connection-state=invalid \
    log=yes log-prefix=lteinvalid out-interface=lte1
/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN
/ip packing
add disabled=yes interface=eoip-wifimesh packing=compress-all unpacking=\
    compress-all
/ip route
add check-gateway=ping comment=\
    "static route to M172-Rizi \"station\" in \"mesh\" wifi" disabled=no \
    distance=12 dst-address=0.0.0.0/0 gateway=192.168.71.72 pref-src="" \
    routing-table=main scope=30 suppress-hw-offload=no target-scope=10
/ip service
set telnet disabled=yes
set ftp disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/ip upnp
set enabled=yes
/ip upnp interfaces
add interface=bridge1 type=internal
add interface=lte1 type=external
/system clock
set time-zone-name=America/Los_Angeles
/system identity
set name=M171-Yizi
/system logging
add topics=debug
/system routerboard settings
set auto-upgrade=yes cpu-frequency=auto
/tool graphing interface
add
/tool netwatch
add down-script=\
    ":log warn \"netwatch ping over local mesh NOT responding within 100ms\"" \
    host=192.168.71.72 interval=1s timeout=100ms up-script=\
    ":log info \"netwatch ping over local mesh responding within 100ms\""
add down-script=\
    ":log info \"netwatch ping to Google NOT responding within 250ms\"" host=\
    8.8.8.8 interval=1s timeout=250ms up-script=\
    ":log debug \"netwatch ping to Google responding within 250ms\""
add down-script=\
    ":log error \"netwatch ping to Google NOT responding within 500ms\"" \
    host=8.8.8.8 interval=1s timeout=500ms up-script=\
    ":log info \"netwatch ping to Google responding within 500ms\""
/tool sms
set port=lte1 receive-enabled=yes
/tool sniffer
set file-limit=10000KiB file-name=wifi-m171.pcap filter-interface=wifi-MeshAP
