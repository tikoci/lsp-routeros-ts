# Source: https://forum.mikrotik.com/t/using-ai-to-help-configuring-routeros-and-scripting/183452/49
# Topic: Using AI to help configuring RouterOS and scripting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# New commands and arguments added in RouterOS 7.19
/certificate builtin find where=
/certificate builtin get as-string= as-string-value= number= value-name=
/certificate builtin print append= as-value= brief= count-only= detail= file="string value" follow= follow-only= from= group-by= interval="00:00:00.200.." proplist= show-ids= terse= value-list= where= without-paging=
/certificate settings set builtin-trust-anchors=
/container add name="string value"
/container reset name="string value"
/container set name="string value"
/disk eject numbers=
/disk format as-value= duration= file-system= freeze-frame-interval="00:00:00.020..00:00:30" label="string value" mbr-partition-table= numbers= without-paging=
/disk btrfs filesystem reset-counters numbers=
/disk btrfs filesystem balance-start data-usage= metadata-usage= system-usage=
/disk btrfs filesystem replace-device device-to-remove-id=
/disk monitor-traffic proplist=
/dude export-db proplist=
/dude import-db proplist=
/dude vacuum-db proplist=
/file print show-hidden=
/file sync monitor proplist=
/for on-error=
/foreach on-error=
/interface bonding add lacp-mode=
/interface bonding monitor proplist=
/interface bonding reset lacp-mode=
/interface bonding set lacp-mode=
/interface bridge mdb add interface=
/interface bridge mdb reset interface=
/interface bridge mdb set interface=
/interface bridge monitor proplist=
/interface bridge msti monitor proplist=
/interface bridge port monitor proplist=
/interface bridge port mst-override monitor proplist=
/interface ethernet cable-test proplist=
/interface ethernet monitor proplist=
/interface l2tp-client monitor proplist=
/interface l2tp-ether monitor proplist=
/interface l2tp-server monitor proplist=
/interface lte esim provision proplist=
/interface lte firmware-upgrade proplist=
/interface lte monitor proplist=
/interface lte settings set link-recovery-timer=
/interface monitor-traffic proplist=
/interface ovpn-client monitor proplist=
/interface ovpn-server monitor proplist=
/interface ppp-client firmware-upgrade proplist=
/interface ppp-client info proplist=
/interface ppp-client monitor proplist=
/interface ppp-server monitor proplist=
/interface pppoe-client monitor proplist=
/interface pppoe-server monitor proplist=
/interface pptp-client monitor proplist=
/interface pptp-server monitor proplist=
/interface sstp-client monitor proplist=
/interface sstp-server monitor proplist=
/interface vpls monitor proplist=
/interface wifi add channel.reselect-time= datapath.traffic-processing=
/interface wifi add security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi channel add reselect-time=
/interface wifi channel reset reselect-time=
/interface wifi channel set reselect-time=
/interface wifi configuration add channel.reselect-time= datapath.traffic-processing=
/interface wifi configuration add security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi configuration reset channel.reselect-time= datapath.traffic-processing=
/interface wifi configuration reset security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi configuration set channel.reselect-time= datapath.traffic-processing=
/interface wifi configuration set security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi datapath add traffic-processing=
/interface wifi datapath reset traffic-processing=
/interface wifi datapath set traffic-processing=
/interface wifi monitor proplist=
/interface wifi reset channel.reselect-time= datapath.traffic-processing=
/interface wifi reset security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi security add authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi security reset authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi security set authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi set channel.reselect-time= datapath.traffic-processing=
/interface wifi set security.authentication-types="wpa-psk|wpa2-psk|wpa2-psk-sha2|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi wps-client proplist=
/interface wireguard wg-import config-file= config-string="string value"
/interface wireless monitor proplist=
/interface wireless nstreme-dual monitor proplist=
/interface wireless setup-repeater proplist=
/interface wireless sniffer sniff proplist=
/interface wireless wds monitor proplist=
/interface wireless wps-client proplist=
/iot lora send bandwidth= device-id= frequency= inverted= modulation= payload="string value" power= preamble= spread-factor=
/iot lora joineui add type=
/iot lora joineui reset type=
/iot lora joineui set type=
/iot lora netid add type=
/iot lora netid reset type=
/iot lora netid set type=
/iot lora reset forward="crc-validation|dev-addr-validation|proprietary-traffic[,Forward*]"
/iot lora set forward="crc-validation|dev-addr-validation|proprietary-traffic[,Forward*]"
/iot lora traffic options set pckt-limit=
/modbus read-holding-registers proplist=
/ip dhcp-client add allow-reconfigure= check-gateway=
/ip dhcp-client reset allow-reconfigure= check-gateway=
/ip dhcp-client set allow-reconfigure= check-gateway=
/ip dhcp-relay monitor proplist=
/ip dhcp-server add use-reconfigure=
/ip dhcp-server lease send-reconfigure numbers=
/ip dhcp-server reset use-reconfigure=
/ip dhcp-server set use-reconfigure=
/ip neighbor unset numbers= value-name=
/ip proxy monitor proplist=
/ip route check proplist=
/ip traffic-flow monitor proplist=
/ipv6 dhcp-client add check-gateway= default-route-tables=
/ipv6 dhcp-client reset check-gateway= default-route-tables=
/ipv6 dhcp-client set check-gateway= default-route-tables=
/ipv6 dhcp-relay monitor proplist=
/ipv6 dhcp-server binding send-reconfigure numbers=
/log print with-extra-info=
/lora send bandwidth= device-id= frequency= inverted= modulation= payload="string value" power= preamble= spread-factor=
/lora joineui add type=
/lora joineui reset type=
/lora joineui set type=
/lora netid add type=
/lora netid reset type=
/lora netid set type=
/lora reset forward="crc-validation|dev-addr-validation|proprietary-traffic[,Forward*]"
/lora set forward="crc-validation|dev-addr-validation|proprietary-traffic[,Forward*]"
/lora traffic options set pckt-limit=
/queue monitor proplist=
/radius incoming monitor proplist=
/radius monitor proplist=
/routing bgp connection add afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing bgp connection reset afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing bgp connection set afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing bgp session refresh afi=
/routing bgp session resend afi=
/routing bgp template add afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing bgp template reset afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing bgp template set afi="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,Afi*]" input.filter-communities= input.filter-ext-communities= input.filter-large-communities= input.filter-unknown=
/routing settings set connected-in-chain= dynamic-in-chain=
/system gps monitor proplist=
/system package update check-for-updates proplist=
/system package update download proplist=
/system package update install proplist=
/system resource monitor proplist=
/system ups monitor proplist=
/tool bandwidth-test proplist=
/tool fetch proplist=
/tool flood-ping proplist=
/tool ping-speed proplist=
/tool sniffer set max-packet-size=
/tool speed-test proplist=
/tool traffic-generator inject-pcap proplist=
/user-manager monitor proplist=
/user-manager router monitor proplist=
/user-manager user monitor proplist=

# Commands and arguments removed in RouterOS 7.19
/certificate enable-ssl-certificate type=
/disk eject-drive numbers=
/disk format-drive as-value= duration="time interval" file-system= freeze-frame-interval="00:00:00.020..00:00:30 (time interval)" label="string value" mbr-partition-table= numbers= without-paging=
/interface amt add comment="string value" copy-from= disabled= discovery-ip="A.B.C.D (IP address)" dont-fragment= gateway-port= interface= local-ip="A.B.C.D (IP address)" mac-address="AB[:|-|.]CD[:|-|.]EF[:|-|.]GH[:|-|.]IJ[:|-|.]KL (MAC address)" max-tunnels= mode= name="string value" relay-port=
/interface amt comment comment="string value" numbers=
/interface amt disable numbers=
/interface amt edit number= value-name=
/interface amt enable numbers=
/interface amt export compact= file="string value" hide-sensitive= show-sensitive= terse= verbose= where=
/interface amt find where=
/interface amt get as-string= as-string-value= number= value-name=
/interface amt print append= as-value= count-only= detail= file="string value" follow= follow-only= from= group-by= interval="00:00:00.200.." proplist= show-ids= terse= value-list= where= without-paging=
/interface amt remove numbers=
/interface amt reset comment="string value" disabled= discovery-ip="A.B.C.D (IP address)" dont-fragment= gateway-port= interface= local-ip="A.B.C.D (IP address)" mac-address="AB[:|-|.]CD[:|-|.]EF[:|-|.]GH[:|-|.]IJ[:|-|.]KL (MAC address)" max-tunnels= mode= name="string value" numbers= relay-port=
/interface amt set comment="string value" disabled= discovery-ip="A.B.C.D (IP address)" dont-fragment= gateway-port= interface= local-ip="A.B.C.D (IP address)" mac-address="AB[:|-|.]CD[:|-|.]EF[:|-|.]GH[:|-|.]IJ[:|-|.]KL (MAC address)" max-tunnels= mode= name="string value" numbers= relay-port=
/interface bridge mdb add ports=
/interface bridge mdb reset ports=
/interface bridge mdb set ports=
/interface eoipv6 add remote-address="see documentation"
/interface eoipv6 reset remote-address="see documentation"
/interface eoipv6 set remote-address="see documentation"
/interface gre6 add remote-address="see documentation"
/interface gre6 reset remote-address="see documentation"
/interface gre6 set remote-address="see documentation"
/interface ipipv6 add remote-address="see documentation"
/interface ipipv6 reset remote-address="see documentation"
/interface ipipv6 set remote-address="see documentation"
/interface wifi add security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi cap set caps-man-addresses="see documentation"
/interface wifi configuration add security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi configuration reset security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi configuration set security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi reset security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wifi security add authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi security reset authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi security set authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,AuthenticationTypes*]"
/interface wifi set security.authentication-types="wpa-psk|wpa2-psk|wpa-eap|wpa2-eap|wpa3-psk|owe|wpa3-eap|wpa3-eap-192[,SecurityAuthenticationTypes*]"
/interface wireguard wg-import file=
/iot lora unset numbers= value-name=
/iot lora reset src-address="A.B.C.D (IP address)"
/iot lora reset forward="crc-validtaion|dev-addr-validtaion|proprietary-traffic[,Forward*]"
/iot lora set src-address="A.B.C.D (IP address)"
/iot lora set forward="crc-validtaion|dev-addr-validtaion|proprietary-traffic[,Forward*]"
/ipv6 route add gateway="see documentation"
/ipv6 route reset gateway="see documentation"
/ipv6 route set gateway="see documentation"
/lora unset numbers= value-name=
/lora reset src-address="A.B.C.D (IP address)"
/lora reset forward="crc-validtaion|dev-addr-validtaion|proprietary-traffic[,Forward*]"
/lora set src-address="A.B.C.D (IP address)"
/lora set forward="crc-validtaion|dev-addr-validtaion|proprietary-traffic[,Forward*]"
/mpls ldp neighbor add transport="see documentation"
/mpls ldp neighbor reset transport="see documentation"
/mpls ldp neighbor set transport="see documentation"
/mpls ldp remote-mapping add nexthop="see documentation"
/mpls ldp remote-mapping reset nexthop="see documentation"
/mpls ldp remote-mapping set nexthop="see documentation"
/routing bgp connection add address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing bgp connection add local.address="see documentation"
/routing bgp connection add remote.address="see documentation"
/routing bgp connection reset address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing bgp connection reset local.address="see documentation"
/routing bgp connection reset remote.address="see documentation"
/routing bgp connection set address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing bgp connection set local.address="see documentation"
/routing bgp connection set remote.address="see documentation"
/routing bgp session refresh address-family=
/routing bgp session resend address-family=
/routing bgp template add address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing bgp template reset address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing bgp template set address-families="ip|ipv6|l2vpn|l2vpn-cisco|vpnv4|vpnv6[,AddressFamilies*]" input.accept-unknown=
/routing fantasy add dst-address="see documentation" gateway="see documentation"
/routing fantasy reset dst-address="see documentation" gateway="see documentation"
/routing fantasy set dst-address="see documentation" gateway="see documentation"
/routing ospf static-neighbor add address="see documentation"
/routing ospf static-neighbor reset address="see documentation"
/routing ospf static-neighbor set address="see documentation"
/routing pimsm bsr candidate add address="see documentation"
/routing pimsm bsr candidate reset address="see documentation"
/routing pimsm bsr candidate set address="see documentation"
/routing pimsm bsr rp-candidate add address="see documentation"
/routing pimsm bsr rp-candidate reset address="see documentation"
/routing pimsm bsr rp-candidate set address="see documentation"
/routing rip static-neighbor add address="see documentation"
/routing rip static-neighbor reset address="see documentation"
/routing rip static-neighbor set address="see documentation"
/tool fetch address="see documentation"
/tool netwatch add host="see documentation"
/tool netwatch reset host="see documentation"
/tool netwatch set host="see documentation"
