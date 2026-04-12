# Source: https://forum.mikrotik.com/t/using-wifiwave2-to-bridge-two-audience-wirelessly-thoughts-4-address-mode/153357/1
# Topic: Using WifiWave2 to bridge two Audience wirelessly, thoughts? == 4-address mode
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# nov/14/2021 10:30:48 by RouterOS 7.1rc6
# software id = 8QEA-KKXK
# model = RBD25GR-5HPacQD2HPnD

/interface bridge
add name=bridge1
/interface lte
set [ find ] allow-roaming=no band="" mtu=1480 name=lte1
/interface eoip
add comment="tunnel using non-bridged \"mesh\" wifi interface to another Audie\
    nce in AP mode, so bridge1 is connect between an in-range peer" \
    local-address=192.168.71.72 mac-address=02:B4:CF:BA:59:9F mtu=1500 name=\
    eoip-wifimesh remote-address=192.168.71.1 tunnel-id=71
/interface vrrp
add comment="use VRRP on bridge1 so only one default route for \"mesh bridge\"\
    \_(if peer cannot connect or is off, each unit still operates independentl\
    y)" interface=bridge1 name=vrrp-bridge1
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/interface lte apn
set [ find default=yes ] apn=broadband ip-type=ipv4 use-peer-dns=no
/interface wifiwave2 security
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=mobileskyfi
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=noproblem
add authentication-types=wpa2-psk,wpa3-psk disable-pmkid=yes name=ztsecure
/interface wifiwave2 configuration
add channel.skip-dfs-channels=all country="United States3" name=SkyTower \
    security=noproblem ssid=SkyTower
add channel.skip-dfs-channels=all country="United States3" hide-ssid=yes \
    name=SkyBridge security=ztsecure ssid=SkyBridge+SkyTower
add channel.skip-dfs-channels=all .width=20mhz country="United States3" name=\
    M172 security=mobileskyfi ssid=M172
/interface wifiwave2
set [ find default-name=wifi1 ] configuration=M172 configuration.mode=ap \
    disabled=no name=wifi-2.4Ghz
set [ find default-name=wifi2 ] configuration=SkyTower configuration.mode=ap \
    disabled=no name=wifi-5Ghz
set [ find default-name=wifi3 ] arp-timeout=30s configuration=SkyBridge \
    configuration.mode=station disabled=no l2mtu=1600 mtu=1550 name=\
    wifi-MeshStation
/ip pool
add name=dhcp ranges=192.168.0.201-192.168.0.249
/ip dhcp-server
add address-pool=dhcp interface=vrrp-bridge1 lease-time=1h name=dhcp1
/routing table
add fib name=""
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp,rest-api"
/zerotier
set zt1 comment="ZeroTier Central controller - https://my.zerotier.com/" \
    identity="xxx" name=zt1 \
    port=9993
/zerotier interface
add instance=zt1 mac-address=2E:28:C3:96:80:D3 name=zerotier1 network=\
    xxx
/interface bridge port
add bridge=bridge1 comment=defconf ingress-filtering=no interface=ether2
add bridge=bridge1 comment=defconf ingress-filtering=no interface=wifi-2.4Ghz
add bridge=bridge1 comment=defconf ingress-filtering=no interface=wifi-5Ghz
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=eoip-wifimesh
/ip neighbor discovery-settings
set discover-interface-list=LAN
/ipv6 settings
set disable-ipv6=yes
/interface list member
add interface=bridge1 list=LAN
add interface=lte1 list=WAN
add interface=ether1 list=LAN
add interface=ether2 list=LAN
add interface=wifi-2.4Ghz list=LAN
add interface=wifi-MeshStation list=LAN
add interface=wifi-5Ghz list=LAN
add interface=vrrp-bridge1 list=LAN
add interface=eoip-wifimesh list=LAN
add interface=zerotier1 list=LAN
/ip address
add address=192.168.0.72/24 interface=bridge1 network=192.168.0.0
add address=192.168.0.1 interface=vrrp-bridge1 network=192.168.0.1
/ip cloud
set ddns-enabled=yes
/ip dhcp-client
add comment=\
    "PtMP Station for \"mesh\" wifi interface (obtain IP from \"hub\" AP)" \
    default-route-distance=21 interface=wifi-MeshStation use-peer-dns=no \
    use-peer-ntp=no
/ip dhcp-server network
add address=192.168.0.0/24 comment="bridge1 LAN (via VRRP)" dns-server=\
    208.67.222.222,8.8.4.4 gateway=192.168.0.1 netmask=24
/ip dns
set servers=208.67.222.222,8.8.4.4
/ip dns static
add address=192.168.88.1 comment=defconf name=router.lan
/ip firewall filter
add action=accept chain=forward comment="allow zerotier" in-interface=\
    zerotier1
add action=accept chain=input comment="allow zerotier" in-interface=zerotier1
add action=accept chain=input protocol=icmp
add action=accept chain=input connection-state=established
add action=accept chain=input connection-state=related
add action=accept chain=input comment="always allow winbox" dst-port=8291 \
    protocol=tcp
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
add check-gateway=ping comment="static route to \"hub\" for internet routing, \
    used if local LTE interface is down" disabled=no distance=15 dst-address=\
    0.0.0.0/0 gateway=192.168.0.71 pref-src="" routing-table=main scope=30 \
    suppress-hw-offload=no target-scope=10
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
set name=M172-Rizi
/system logging
add topics=debug
/system package update
set channel=development
/system routerboard settings
set auto-upgrade=yes cpu-frequency=auto
/tool graphing interface
add
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
/tool netwatch
add down-script=\
    ":log warn \"netwatch ping over local mesh NOT responding within 100ms\"" \
    host=192.168.71.1 interval=1s timeout=100ms up-script=\
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
set file-limit=10000KiB file-name=wifi-m172.pcap filter-interface=\
    wifi-MeshStation
