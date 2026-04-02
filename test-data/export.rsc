# 2025-06-27 19:33:44 by RouterOS 7.20beta4
# software id = BV5A-5GB9
#
# model = RB1100Dx4
# serial number = 9BD90A1189F6
/container mounts
add dst=/homebridge name=homebridge src=disk1/homebridge-data
add comment="Caddyfile config" dst=/etc/caddy/Caddyfile name=caddy src=\
    disk2/etc/caddy/Caddyfile
/disk
set disk1 slot=disk1
set disk2 slot=disk2
/interface bridge
add igmp-snooping=yes mvrp=yes name=bridge vlan-filtering=yes
/interface eoip
add disabled=yes mac-address=02:B0:B3:FC:F4:D9 name=eoip-P202 remote-address=\
    aeea0a34bf44.sn.mynetname.net tunnel-id=202
add mac-address=02:A6:12:A1:E2:45 mtu=1500 name=eoip-drum2-mg remote-address=\
    172.31.4.82 tunnel-id=82
add allow-fast-path=no mac-address=FE:59:52:87:2C:BF mtu=1500 name=eoip-dsi \
    remote-address=dsi.skyfi.link tunnel-id=163
/interface veth
add address=172.19.55.2/24 comment=test dhcp=no gateway=172.19.55.1 gateway6=\
    "" mac-address=22:C9:D6:0A:5C:E1 name=veth-caddy
add address=172.19.7.7/24 dhcp=no gateway=172.19.7.1 gateway6="" mac-address=\
    60:EC:B3:6D:02:67 name=veth-faucet
add address=192.168.74.249/24 dhcp=no gateway=192.168.74.1 gateway6="" name=\
    veth-homebridge-lan
add address=192.168.74.205/24 dhcp=no gateway=192.168.74.1 gateway6="" \
    mac-address=2C:54:04:A5:D4:C0 name=veth-maked1
/interface vrrp
add interface=bridge name=vr-lan-bridge
/interface wireguard
add comment=back-to-home-vpn listen-port=35431 mtu=1420 name=back-to-home-vpn
/interface vlan
add interface=bridge mvrp=yes name=vlan10-fiber vlan-id=10
add interface=bridge mvrp=yes name=vlan163-dsi vlan-id=163
/interface macvlan
add interface=ether6 mac-address=12:0A:A6:AC:4A:7C mode=private name=macvlan1
/interface vrrp
add interface=vlan10-fiber name=vr-lan-fiber vrid=74
add interface=vlan10-fiber name=vr-wan-fiber vrid=14
/interface list
add name=WAN
add name=LAN
/iot lora servers
add address=eu1.cloud.thethings.industries name="TTS Cloud (eu1)" protocol=\
    UDP
add address=nam1.cloud.thethings.industries name="TTS Cloud (nam1)" protocol=\
    UDP
add address=au1.cloud.thethings.industries name="TTS Cloud (au1)" protocol=\
    UDP
add address=eu1.cloud.thethings.network name="TTN V3 (eu1)" protocol=UDP
add address=nam1.cloud.thethings.network name="TTN V3 (nam1)" protocol=UDP
add address=au1.cloud.thethings.network name="TTN V3 (au1)" protocol=UDP
/ip pool
add name=dhcp ranges=172.22.74.201-172.22.74.249
add name=vpn ranges=192.168.89.2-192.168.89.255
add name=remotes ranges=172.31.4.10-172.31.4.249
/ip dhcp-server
add address-pool=dhcp interface=bridge name=dhcp1
/ip smb users
add name=skyfi
/openflow
add controllers=tcp/172.19.7.7/6653 datapath-id=0/00:00:00:00:00:07 disabled=\
    no name=faucet verify-peer=none version=1.3
/port
set 0 name=serial0
set 1 name=serial1
/ppp profile
add change-tcp-mss=yes interface-list=LAN local-address=172.31.4.1 name=\
    remotes remote-address=remotes use-encryption=yes
set *FFFFFFFE local-address=192.168.89.1 remote-address=vpn
/snmp community
set [ find default=yes ] disabled=yes
add addresses=::/0,0.0.0.0/0 name=mobileskyfi
/system logging action
add name=fetch target=echo
add disk-file-name=disk2/dns disk-lines-per-file=10000 name=dnsfile target=\
    disk
/user group
set read policy="local,telnet,ssh,reboot,read,test,winbox,password,web,sniff,a\
    pi,romon,rest-api,!ftp,!write,!policy,!sensitive"
add name=lsp policy="read,api,rest-api,!local,!telnet,!ssh,!ftp,!reboot,!write\
    ,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon"
/zerotier
set zt1 disabled=no disabled=no interfaces=WAN route-distance=9
/zerotier interface
add allow-default=no allow-global=no allow-managed=yes disabled=no instance=\
    zt1 name=zt-rqs.la network=12ac4a1e71f63b8b
add allow-default=no allow-global=no allow-managed=yes disabled=no instance=\
    zt1 name=zt-skyfi.link network=565799d8f6469d2f
/certificate scep-server
add ca-cert=tikoci-ca-router path=/scep/tikoci
/container
add check-certificate=no interface=veth-faucet logging=yes name=faucet \
    root-dir=disk1/faucet start-on-boot=yes
# exited with status 2
add interface=veth-maked1 logging=yes name=maked1 root-dir=disk1/maked1-root1 \
    start-on-boot=yes workdir=/app
add check-certificate=no interface=veth-caddy logging=yes mounts=caddy name=\
    caddy root-dir=disk2/caddy-root-3 start-on-boot=yes workdir=/srv
/container envs
add key=PROXY_TO_URL list=traefik-proxy value=http://192.168.74.1:80/
add key=TRAEFIK_API_INSECURE list=traefik-proxy value=true
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME list=traefik-proxy \
    value=true
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL list=\
    traefik-proxy value=shafdog@gmail.com
add key=\
    TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_HTTPCHALLENGE_ENTRYPOINT \
    list=traefik-proxy value=web
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_STORAGE list=\
    traefik-proxy value=/etc/traefik/acme.json
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS list=traefik-proxy value=:8443
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS list=traefik-proxy value=true
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS_CERTRESOLVER list=\
    traefik-proxy value=letsencrypt
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS_DOMAINS_1_MAIN list=\
    traefik-proxy value=9bd90a1189f6.sn.mynetname.net
add key=TRAEFIK_ENTRYPOINTS_WEB_ADDRESS list=traefik-proxy value=:8081
add key=TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_TO list=\
    traefik-proxy value=websecure
add key=TRAEFIK_LOG_LEVEL list=traefik-proxy value=DEBUG
add key=TRAEFIK_LOG_NOCOLOR list=traefik-proxy value=false
add key=TRAEFIK_PROVIDERS_FILE_DIRECTORY list=traefik-proxy value=\
    /etc/traefik
add key=TRAEFIK_PROVIDERS_FILE_WATCH list=traefik-proxy value=true
add key=TRAEFIK_SERVERSTRANSPORT_INSECURESKIPVERIFY list=traefik-proxy value=\
    true
/dude
set data-directory=disk1/dude1
/interface bridge port
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether2
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether3
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether4
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether5
add bridge=bridge interface=ether8
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether9
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether10 pvid=163
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether11
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether12
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether13 pvid=10
add bridge=bridge interface=ether1
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=eoip-dsi pvid=163
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=veth-homebridge-lan pvid=10
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=eoip-drum2-mg pvid=10
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=veth-maked1 pvid=10
/ip neighbor discovery-settings
set discover-interface-list=all discover-interval=10s
/interface detect-internet
set detect-interface-list=WAN
/interface l2tp-server server
set use-ipsec=yes
/interface list member
add interface=bridge list=LAN
add interface=eoip-dsi list=LAN
add interface=vlan10-fiber list=LAN
add interface=vr-wan-fiber list=WAN
add interface=zt-rqs.la list=LAN
add interface=vr-lan-fiber list=LAN
add interface=zt-skyfi.link list=LAN
add interface=eoip-drum2-mg list=LAN
add interface=veth-caddy list=LAN
/interface sstp-server server
set default-profile=remotes enabled=yes port=8443
/ip address
add address=172.22.74.254/24 interface=bridge network=172.22.74.0
add address=108.211.142.61/29 interface=vr-wan-fiber network=108.211.142.56
add address=192.168.74.1 interface=vr-lan-fiber network=192.168.74.1
add address=172.22.74.1 interface=vr-lan-bridge network=172.22.74.1
add address=172.19.7.1/24 comment=faucet interface=veth-faucet network=\
    172.19.7.0
add address=172.18.18.1/24 interface=*3D network=172.18.18.0
add address=172.19.55.1/24 interface=veth-caddy network=172.19.55.0
/ip cloud
set back-to-home-vpn=enabled ddns-enabled=yes
/ip cloud back-to-home-file
add disabled=yes path=/disk1/tikbook-0.1.1.vsix
# Share expired
add expires="2025-06-26 15:21:50" path=/tikoci-ca-router.crt
/ip cloud back-to-home-user
add allow-lan=yes name=drum2-mg private-key=\
    "OPvSAnZbSyAzWZv9vb6DB868VA+/UhGcJaiUCFYCYmU=" public-key=\
    "e32xf+0z7WakePw9luV2VrZqsIMLBM9EuThNY15FOXw="
/ip dhcp-client
add default-route-distance=2 interface=vlan10-fiber
add default-route-distance=3 interface=vlan163-dsi use-peer-dns=no \
    use-peer-ntp=no
# Interface not active
add add-default-route=no interface=macvlan1 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network
add address=172.22.74.0/24 gateway=172.22.74.254 netmask=24
/ip dns
set servers=1.1.1.1
/ip dns static
add address=192.168.74.122 name=roku type=A
/ip firewall address-list
add address=dsi.skyfi.link list=dsi.skyfi.link
add address=aeea0a34bf44.sn.mynetname.net comment=P202 list=skyfi-remotes
add address=192.168.74.0/24 list=att-fiber-lan
/ip firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=accept chain=input comment="accept EoIP tunnel" protocol=gre \
    src-address-list=dsi.skyfi.link
add action=accept chain=input comment="accept SSTP tunnel on 8443" dst-port=\
    8443 protocol=tcp
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment="allow btest (TCP)" port=2000-2100 \
    protocol=tcp
add action=accept chain=input comment="allow https (TCP)" dst-port=443 \
    protocol=tcp
add action=accept chain=input comment="allow http (TCP)" dst-port=80 \
    protocol=tcp
add action=accept chain=input comment="allow btest (UDP)" port=2000-2100 \
    protocol=udp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=accept chain=input comment=\
    "drop all not coming from LAN (via address-list)" src-address-list=\
    att-fiber-lan
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related hw-offload=yes
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
/ip firewall nat
add action=dst-nat chain=dstnat dst-port=443 log=yes protocol=tcp \
    src-address=!172.19.55.2 to-addresses=172.19.55.2 to-ports=443
add action=dst-nat chain=dstnat dst-port=80 protocol=tcp src-address=\
    !172.19.55.2 to-addresses=172.19.55.2 to-ports=80
add action=masquerade chain=srcnat out-interface-list=WAN
add action=masquerade chain=srcnat out-interface=vlan10-fiber
add action=masquerade chain=srcnat out-interface=vr-lan-bridge
add action=masquerade chain=srcnat comment="masq. vpn traffic" src-address=\
    192.168.89.0/24
add action=masquerade chain=srcnat comment="masq. sstp traffic" dst-address=\
    172.31.4.0/24
add action=masquerade chain=srcnat disabled=yes out-interface=veth-caddy
/ip hotspot user
add limit-uptime=1d name=user1
/ip ipsec profile
set [ find default=yes ] enc-algorithm=aes-256,aes-128,3des
/ip route
add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=\
    108.211.142.62 routing-table=main scope=30 suppress-hw-offload=no \
    target-scope=10
/ip service
set www port=7080
set www-ssl certificate="Lets encrypt1749743170" disabled=no port=7443
/ip smb shares
add directory=disk1 name=disk1 valid-users=skyfi
/ip socks
set enabled=yes
/ip socks access
add
/ip ssh
set always-allow-password-login=yes
/ipv6 dhcp-client
add add-default-route=yes allow-reconfigure=yes interface=vlan10-fiber \
    pool-name=fiber request=address,prefix use-peer-dns=no
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" port=\
    33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
/openflow port
add disabled=no interface=ether6 port-id=1 switch=faucet
add disabled=no interface=ether7 port-id=2 switch=faucet
/ppp secret
add name=vpn
add name=drum82-mg remote-address=172.31.4.82 routes=\
    "192.168.82.0/24 172.31.4.82 2"
/snmp
set enabled=yes trap-community=mobileskyfi
/system clock
set time-zone-name=America/Los_Angeles
/system gps
set coordinate-format=dms port=serial0
/system identity
set name=bigdude
/system logging
add action=fetch topics=fetch
add topics=certificate
add action=dnsfile topics=dns
/system package update
set channel=testing
/system routerboard settings
set auto-upgrade=yes
/system script
add dont-require-permissions=no name=roku owner=skyfi policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n# \$ROKU - the missing remote for RouterOS\
    \n\
    \n\
    \n:global ROKU\
    \n:global debug 0\
    \n\
    \n# helpers types\
    \n:global \"roku-rcpmap\"\
    \n:global \"roku-sendkey\"\
    \n\
    \n# UDP port for communication with roku (set later, default is 8060)\
    \n:global \"roku-active-rcpport\"\
    \n\
    \n# RouterOS ASCII mappings \
    \n:global \"ascii-map\"\
    \n:global \"ascii-name\"\
    \n\
    \n# main command function\
    \n:set ROKU do={\
    \n    # no keyboard events, so poll for keypresses every...\
    \n    :local loopdelay 100ms\
    \n    \
    \n    # global used variables must be defined\
    \n    :global ROKU\
    \n    :global \"roku-rcpmap\"\
    \n    :global \"roku-sendkey\"\
    \n    :global \"ascii-map\"\
    \n    :global \"ascii-name\" \
    \n    :global \"roku-active-rcpport\"\
    \n\
    \n    # default is port 8060\
    \n    :if ([:typeof (\$\"roku-active-rcpport\")]!=\"num\") do={ \
    \n        :set \"roku-active-rcpport\" 8060\
    \n    }\
    \n \
    \n   \
    \n    # we require some command after \$ROKU, like help or remote...\
    \n    :if ([typeof \$1]=\"str\") do={\
    \n        # if it's a known command, like \"\$ROKU back\", easy...\
    \n        :local cmd (\$\"roku-rcpmap\"->\$1->\"cmd\")\
    \n        :if ([:typeof \$cmd]=\"str\") do={\
    \n            :local sendkeyout [\$\"roku-sendkey\" \$1]\
    \n            :put \"\\\$ROKU '\$1' sent to \$sendkeyout\"\
    \n            :return \$sendkeyout\
    \n        }\
    \n        # interactive remote use \"\$ROKU remote\"...\
    \n        :if (\$1=\"remote\") do={\
    \n            # first, output possible commands            \
    \n            :put \"\\t   ALL  \\t            TV ONLY\"\
    \n\
    \n            # & process \$\"roku-rcpmap\" for output and\
    \n            # as a \"pivot\" rcpmap on keypress (e.g. lookup table for k\
    eypress to roku cmds)\
    \n            :local cmdkeymap [:toarray \"\"]\
    \n            :local lastcol -1\
    \n            :foreach k,v in=(\$\"roku-rcpmap\") do={ \
    \n                :local hit (\$v->\"keypress\")\
    \n                :local tags (\$v->\"tags\")\
    \n                :local cmd (\$v->\"cmd\")\
    \n                :if (\$tags~\"tv\") do={\
    \n                    :if (\$lastcol=0) do={/terminal cuu}\
    \n                    :put \"\\t\\t\\t\\t\$hit - \$cmd\"\
    \n                    :set \$lastcol 1\
    \n                } else={\
    \n                    :if (\$lastcol=1) do={/terminal cuu}\
    \n                    :put \"\$hit - \$cmd\"\
    \n                    :set \$lastcol 0\
    \n                }\
    \n                :set (\$cmdkeymap->\"\$hit\") \$cmd\
    \n            }\
    \n            # always map array keys\
    \n            :set (\$cmdkeymap->\"up\") \"Up\"\
    \n            :set (\$cmdkeymap->\"down\") \"Down\"\
    \n            :set (\$cmdkeymap->\"left\") \"Left\"\
    \n            :set (\$cmdkeymap->\"right\") \"right\"\
    \n            :put \"\"\
    \n\
    \n            :local keyed 65535\
    \n            :local started 1\
    \n            :local keyboard 0\
    \n            :while (\$started) do={ \
    \n                :local keyname [\$\"ascii-name\" \$keyed]\
    \n         \
    \n                :if (\$keyname=\"`\") do={\
    \n                    :if (\$keyboard=1) do={\
    \n                        :set keyboard 0\
    \n                        /terminal cuu\
    \n                    } else={\
    \n                        :set keyboard 1\
    \n                        :put \"KEYBOARD MODE ACTIVE               \"\
    \n                    }\
    \n                }\
    \n                :if (\$keyboard=0 && [:typeof (\$cmdkeymap->\"\$keyname\
    \")]=\"str\") do={\
    \n                        :local sendkeyout [\$\"roku-sendkey\" (\$cmdkeym\
    ap->\"\$keyname\")]\
    \n                        :put \"\\\$ROKU \$sendkeyout SENT \$((\$cmdkeyma\
    p->\"\$keyname\"))\"\
    \n                        :set keyed 65535\
    \n                        /terminal cuu\
    \n                } else={\
    \n                    :if (\$keyboard=1 && \$keyname~\"^([A-z0-9]|\\\\.|en\
    ter|space|back)\\\$\") do={\
    \n                        :local litkey \"Lit_\$keyname\"\
    \n                        :if (\$keyname=\"enter\") do={:set litkey \"Ente\
    r\"}\
    \n                        :if (\$keyname=\"space\") do={:set litkey \"Lit_\
    %20\"}\
    \n                        :if (\$keyname=\"back\") do={:set litkey \"Backs\
    pace\"}\
    \n                        \$\"roku-sendkey\" \$litkey\
    \n                        /terminal cuu \
    \n                        :put \"\\t\\t\\t\\t     sent \$litkey      \"\
    \n                    }\
    \n                }                \
    \n                :if (\$keyboard=0 && \$keyname~\"q|Q|x|X\") do={\
    \n                    :return \"Quiting Roku Remote...\"\
    \n                }\
    \n                :set keyed [/terminal inkey timeout=\$loopdelay]\
    \n            }\
    \n            :return \"\"\
    \n        }\
    \n        :if (\$1=\"help\") do={\
    \n            :put \"\\\$ROKU - the missing remote for Mikrotik\"\
    \n            :put \"   \\\$ROKU remote  -  interactive remote using vi-li\
    ke key maps\"\
    \n            :put \"   \\\$ROKU set ip=<roku_ip> - set Roku IP address as\
    \_a static DNS name 'roku'\"\
    \n            :put \"   \\\$ROKU <cmd>  -  issues a single Roku remote con\
    trol command, specifically:\"\
    \n            :foreach k,v in=(\$\"roku-rcpmap\") do={\
    \n                :local requires \"\"\
    \n                :if ((\$v->\"tags\")~\"tv\") do={\
    \n                    :set requires \"(requires TV with built-in Roku)\"\
    \n                }\
    \n                :put \"\\t\\\$ROKU \$k \\t\$requires\"\
    \n            }\
    \n            :return \"\"\
    \n        }\
    \n        :if (\$1=\"set\") do={\
    \n            :if ([:typeof [:toip \$ip]]=\"ip\") do={\
    \n                :local rokudns [/ip dns static find name=\"roku\"]\
    \n                :if ([:len \$rokudns]=1) do={\
    \n                    /ip dns static set \$rokudns address=\$ip\
    \n                } else={\
    \n                    /ip dns static add name=roku address=\$ip type=A\
    \n                }\
    \n            }\
    \n            :if ([:typeof \$port]=\"str\") do={\
    \n                :set (\$\"roku-active-rcpport\") [:tonum \$port]\
    \n            }\
    \n            :return \"\"\
    \n        }\
    \n        :if (\$1=\"print\") do={\
    \n            :put \"\\t ip: \\t \$[:resolve roku]\"\
    \n            :put \"\\t port: \\t \$(\$\"roku-active-rcpport\")\"\
    \n            :return \"\"\
    \n        }\
    \n    }\
    \n\
    \n    [\$ROKU help]\
    \n}\
    \n\
    \n:global \"roku-sendkey\"\
    \n:set \"roku-sendkey\" do={\
    \n    :global \"roku-rcpmap\"\
    \n    :global \"roku-active-rcpport\"\
    \n    :global debug\
    \n    :local rokuip [:resolve roku]\
    \n    :local rokuport (\$\"roku-active-rcpport\")\
    \n    :if ([:typeof \$rokuip]!=\"ip\") do={\
    \n        :put \"Problem! \\\$ROKU does a DNS lookup for 'roku'. To fix, u\
    se a static DNS entry with the IP of your Roku devices\"\
    \n        :error \"\\\$ROKU 'roku' does not resolve to an IP address.  An \
    IP address of a Roku device is required.\"\
    \n    }\
    \n    :if (\$1=\"Lit\") do={:return \"\$rokuip:\$rokuport\"}\
    \n    :local rokurl \"http://\$rokuip:\$rokuport/keypress/\$1\"\
    \n    :if (\$debug = 1) do={\
    \n        :put \"DEBUG: sending \$rokurl\"\
    \n    } \
    \n    :do command={\
    \n        :local out [/tool fetch http-method=post output=none url=\$rokur\
    l as-value]\
    \n    } on-error={:put \"Unsupported command.\"; /terminal cuu}\
    \n    :return \"\$rokuip:\$rokuport\"\
    \n}\
    \n\
    \n# KV array mapping roku commands to keyboard\
    \n# (tags= is used by help to organize the grouping)\
    \n:global \"roku-rcpmap\" \
    \n:set \"roku-rcpmap\" {\
    \n    \"home\"={\
    \n        cmd=\"Home\";\
    \n        keypress=\"tab\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"reverse\"={\
    \n        cmd=\"Rev\";\
    \n        keypress=\"b\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"forward\"={\
    \n        cmd=\"Fwd\";\
    \n        keypress=\"f\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"play\"={\
    \n        cmd=\"Play\";\
    \n        keypress=\"space\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"select\"={\
    \n        cmd=\"Select\";\
    \n        keypress=\"enter\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"left\"={\
    \n        cmd=\"Left\";\
    \n        keypress=\"h\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"right\"={\
    \n        cmd=\"Right\";\
    \n        keypress=\"l\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"down\"={\
    \n        cmd=\"Down\";\
    \n        keypress=\"j\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"up\"={\
    \n        cmd=\"Up\";\
    \n        keypress=\"k\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"back\"={\
    \n        cmd=\"Back\";\
    \n        keypress=\"back\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"replay\"={\
    \n        cmd=\"InstantReplay\";\
    \n        keypress=\"r\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"info\"={\
    \n        cmd=\"Info\";\
    \n        keypress=\"i\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"backspace\"={\
    \n        cmd=\"Backspace\";\
    \n        keypress=\"left\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"search\"={\
    \n        cmd=\"Search\";\
    \n        keypress=\"/\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"enter\"={\
    \n        cmd=\"Enter\";\
    \n        keypress=\"enter\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"literal\"={\
    \n        cmd=\"Lit\";\
    \n        keypress=\"`\";\
    \n        tags={\"\"}\
    \n    };\
    \n    \"find_remote\"={\
    \n        cmd=\"FindRemote\";\
    \n        keypress=\"F\";\
    \n        tags={\"find\"}\
    \n    };\
    \n    \"volume_down\"={\
    \n        cmd=\"VolumeDown\";\
    \n        keypress=\"-\";\
    \n        tags={\"tv\"}\
    \n    };\
    \n    \"volume_up\"={\
    \n        cmd=\"VolumeUp\";\
    \n        keypress=\"+\";\
    \n        tags={\"tv\"}\
    \n    };\
    \n    \"volume_mute\"={\
    \n        cmd=\"VolumeMute\";\
    \n        keypress=\"0\";\
    \n        tags={\"tv\"}\
    \n    };\
    \n    \"channel_up\"={\
    \n        cmd=\"ChannelUp\";\
    \n        keypress=\"up\";\
    \n        tags={\"tv\";\"channel\"}\
    \n    };\
    \n    \"channel_down\"={\
    \n        cmd=\"ChannelDown\";\
    \n        keypress=\"down\";\
    \n        tags={\"tv\";\"channel\"}\
    \n    };\
    \n    \"input_tuner\"={\
    \n        cmd=\"InputTuner\";\
    \n        keypress=\"t\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"input_hdmi1\"={\
    \n        cmd=\"InputHDMI1\";\
    \n        keypress=\"1\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"input_hdmi2\"={\
    \n        cmd=\"InputHDMI2\";\
    \n        keypress=\"2\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"input_hdmi3\"={\
    \n        cmd=\"InputHDMI3\";\
    \n        keypress=\"3\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"input_hdmi4\"={\
    \n        cmd=\"InputHDMI4\";\
    \n        keypress=\"4\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"input_av1\"={\
    \n        cmd=\"InputAV1\";\
    \n        keypress=\"!\";\
    \n        tags={\"tv\";\"input\"}\
    \n    };\
    \n    \"power\"={\
    \n        cmd=\"Power\";\
    \n        keypress=\"\\\\\";\
    \n        tags={\"tv\";\"power\"}\
    \n    };\
    \n    \"poweroff\"={\
    \n        cmd=\"PowerOff\";\
    \n        keypress=\"P\";\
    \n        tags={\"tv\";\"power\"}\
    \n    };\
    \n    \"poweron\"={\
    \n        cmd=\"PowerOn\";\
    \n        keypress=\"p\";\
    \n        tags={\"tv\";\"power\"}\
    \n    }\
    \n}\
    \n\
    \n# function, takes \$1 a num result from [/terminal inkey] \
    \n#           and maps to name a string name like \"tab\" or \"enter\"\
    \n:global \"ascii-name\"\
    \n:set \"ascii-name\" do={\
    \n    :global \"ascii-map\"\
    \n    :local keyname \"\"\
    \n    :local keyed [:tonum \$1]\
    \n    :if (\$keyed<255) do={\
    \n        :set keyname (\$\"ascii-map\"->\$keyed)\
    \n        #:put \$keyname\
    \n    } else={\
    \n        :if (\$keyed=65535) do={ :set keyname \"timeout\" }\
    \n        :if (\$keyed=60929) do={ :set keyname \"left\" }\
    \n        :if (\$keyed=60930) do={ :set keyname \"right\" }\
    \n        :if (\$keyed=60931) do={ :set keyname \"up\" }\
    \n        :if (\$keyed=60932) do={ :set keyname \"down\" }\
    \n    }\
    \n    :return \$keyname\
    \n}\
    \n\
    \n# array of str, with array index match the ascii code with value being t\
    he str name \
    \n:global \"ascii-map\"\
    \n:set \"ascii-map\" {\"\";\"NUL\";\"SOH\";\"STX\";\"ETX\";\"EOT\";\"ENQ\"\
    ;\"ACK\";\"back\";\"back\";\"tab\";\"VT\";\"FF\";\"enter\";\"return\";\"SI\
    \";\"DLE\";\"DC1\";\"DC2\";\"DC3\";\"DC4\";\"NAK\";\"SYN\";\"ETB\";\"CAN\"\
    ;\"EM\";\"SUB\";\"ESC\";\"FS\";\"GS\";\"RS\";\"US\";\"space\";\"!\";\"\\\"\
    \";\"comment\";\"\\\$\";\"%\";\"&\";\"\";\"(\";\")\";\"*\";\"+\";\",\";\"-\
    \";\".\";\"/\";\"0\";\"1\";\"2\";\"3\";\"4\";\"5\";\"6\";\"7\";\"8\";\"9\"\
    ;\":\";\";\";\"<\";\"=\";\">\";\"\\\?\";\"@\";\"A\";\"B\";\"C\";\"D\";\"E\
    \";\"F\";\"G\";\"H\";\"I\";\"J\";\"K\";\"L\";\"M\";\"N\";\"O\";\"P\";\"Q\"\
    ;\"R\";\"S\";\"T\";\"U\";\"V\";\"W\";\"X\";\"Y\";\"Z\";\"[\";\"\\\\\";\"]\
    \";\"^\";\"_\";\"`\";\"a\";\"b\";\"c\";\"d\";\"e\";\"f\";\"g\";\"h\";\"i\"\
    ;\"j\";\"k\";\"l\";\"m\";\"n\";\"o\";\"p\";\"q\";\"r\";\"s\";\"t\";\"u\";\
    \"v\";\"w\";\"x\";\"y\";\"z\";\"{\";\"|\";\"}\";\"~\";\"delete\";\"\\80\";\
    \"\\81\";\"\\82\";\"\\83\";\"\\84\";\"\\85\";\"\\86\";\"\\87\";\"\\88\";\"\
    \\89\";\"\\8A\";\"\\8B\";\"\\8C\";\"\\8D\";\"\\8E\";\"\\8F\";\"\\90\";\"\\\
    91\";\"\\92\";\"\\93\";\"\\94\";\"\\95\";\"\\96\";\"\\97\";\"\\98\";\"\\99\
    \";\"\\9A\";\"\\9B\";\"\\9C\";\"\\9D\";\"\\9E\";\"\\9F\";\"\\A0\";\"\\A1\"\
    ;\"\\A2\";\"\\A3\";\"\\A4\";\"\\A5\";\"\\A6\";\"\\A7\";\"\\A8\";\"\\A9\";\
    \"\\AA\";\"\\AB\";\"\\AC\";\"\\AD\";\"\\AE\";\"\\AF\";\"\\B0\";\"\\B1\";\"\
    \\B2\";\"\\B3\";\"\\B4\";\"\\B5\";\"\\B6\";\"\\B7\";\"\\B8\";\"\\B9\";\"\\\
    BA\";\"\\BB\";\"\\BC\";\"\\BD\";\"\\BE\";\"\\BF\";\"\\C0\";\"\\C1\";\"\\C2\
    \";\"\\C3\";\"\\C4\";\"\\C5\";\"\\C6\";\"\\C7\";\"\\C8\";\"\\C9\";\"\\CA\"\
    ;\"\\CB\";\"\\CC\";\"\\CD\";\"\\CE\";\"\\CF\";\"\\D0\";\"\\D1\";\"\\D2\";\
    \"\\D3\";\"\\D4\";\"\\D5\";\"\\D6\";\"\\D7\";\"\\D8\";\"\\D9\";\"\\DA\";\"\
    \\DB\";\"\\DC\";\"\\DD\";\"\\DE\";\"\\DF\";\"\\E0\";\"\\E1\";\"\\E2\";\"\\\
    E3\";\"\\E4\";\"\\E5\";\"\\E6\";\"\\E7\";\"\\E8\";\"\\E9\";\"\\EA\";\"\\EB\
    \";\"\\EC\";\"\\ED\";\"\\EE\";\"\\EF\";\"\\F0\";\"\\F1\";\"\\F2\";\"\\F3\"\
    ;\"\\F4\";\"\\F5\";\"\\F6\";\"\\F7\";\"\\F8\";\"\\F9\";\"\\FA\";\"\\FB\";\
    \"\\FC\";\"\\FD\";\"\\FE\";\"\\FF\"}"
add dont-require-permissions=no name=chalk owner=skyfi policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n:global CHALK do={\
    \n    # we may call ourselves for control codes, so declare that\
    \n    :global CHALK\
    \n    :local helptext \"\\\
    \n    \\r\\n \\\$CHALK\
    \n    \\r\\n  generates ANSI codes that can be used in a string to add col\
    orized text\\\
    \n    \\r\\n \\\
    \n    \\r\\n Basic Syntax:\\\
    \n    \\r\\n     \\\$CHALK <text-color> [<text>] [inverse=yes] [[bold=yes]\
    |[dim=yes]]\\\
    \n    \\r\\n \\\
    \n    \\r\\n Alternatively, use set background (bg=) color, instead of inv\
    erse=yes:\\\
    \n    \\r\\n     \\\$CHALK <text-color> [<text>] bg=<text-color> [[bold=ye\
    s]|[dim=yes]]\\\
    \n    \\r\\n \\\
    \n    \\r\\n View possible values of <text-color>:\\\
    \n    \\r\\n     \\\$CHALK colors\\\
    \n    \\r\\n \\\
    \n    \\r\\n Clear all ANSI formatting:\\\
    \n    \\r\\n     \\\$CHALK reset\\\
    \n    \\r\\n \\\
    \n    \\r\\n Clear only foreground and background colors:\\\
    \n    \\r\\n     \\\$CHALK no-style\\\
    \n    \\r\\n \\\
    \n    \\r\\n Generate a \\\"clickable\\\" URL (in select terminals only):\
    \\\
    \n    \\r\\n     \\\$CHALK url \\\"http://example.com\\\" text=\\\"Example\
    \_Link\\\"\\\
    \n    \\r\\n \\\
    \n    \\r\\n To see this page, use:\\\
    \n    \\r\\n     \\\$CHALK help\\\
    \n    \\r\\n \\\
    \n    \\r\\n Example: \\\
    \n    \\r\\n     Print (\\\"put\\\") some text in cyan -\\\
    \n    \\r\\n         \\\$CHALK cyan \\\"hello world\\\" \\\
    \n    \\r\\n \\\
    \n    \\r\\n     Output blue text inside a string -\\\
    \n    \\r\\n         :put \\\"\\\$[\\\$CHALK blue]hello world\\\$[\\\$CHAL\
    K no-style]\\\"\\\
    \n    \\r\\n \\\
    \n    \\r\\n     Shout bold text with background color (using inverse=yes)\
    \_-\\\
    \n    \\r\\n         :put \\\"\\\$[\\\$CHALK red inverse=yes bold=yes]HELL\
    O WORLD\\\$[\\\$CHALK no-style]\\\"\\\
    \n    \\r\\n \\\
    \n    \\r\\n     Create a click-able URL -\\\
    \n    \\r\\n         :put \\\"\\\$[\\\$CHALK url \\\"http://www.mikrotik.c\
    om\\\" text=\\\"Go to Mikrotik Website\\\"]\\\" \\\
    \n    \\r\\n             ** only works when connected via SSH & using \\\"\
    modern\\\" terminal\\\
    \n    \\r\\n \\\
    \n    \\r\\n     Show example colors -\\\
    \n    \\r\\n         \\\$CHALK colors \\\
    \n    \\r\\n \"    \
    \n    \
    \n    # handle 8-bit color names\
    \n    :local lookupcolor8 do={\
    \n        :local color8 {\
    \n            black={30;40};\
    \n            red={31;41};\
    \n            green={32;42};\
    \n            yellow={33;43};\
    \n            blue={34;44};\
    \n            magenta={35;45};\
    \n            cyan={36;46};\
    \n            white={37;47};\
    \n            \"no-style\"={39;49};\
    \n            reset={0;0};\
    \n            \"bright-black\"={90;0};\
    \n            \"gray\"={90;100};\
    \n            \"grey\"={90;100};\
    \n            \"bright-red\"={91;101};\
    \n            \"bright-green\"={92;103};\
    \n            \"bright-yellow\"={93;104};\
    \n            \"bright-blue\"={94;104};\
    \n            \"bright-magenta\"={95;105};\
    \n            \"bright-cyan\"={96;106};\
    \n            \"bright-white\"={97;107}\
    \n        }\
    \n        :if (\$1 = \"as-array\") do={:return \$color8}\
    \n        :if ([:typeof (\$color8->\$1)]=\"array\") do={\
    \n            :return (\$color8->\$1) \
    \n        } else={\
    \n            :return [:nothing]\
    \n        }\
    \n    }\
    \n\
    \n    :if (\$1 = \"color\") do={\
    \n        :if ([:typeof \$2] = \"str\") do={\
    \n            :local ccode [\$lookupcolor8 \$2]\
    \n            :if ([:len \$ccode] > 0) do={\
    \n                :put \$ccode \
    \n                :return [:nothing]\
    \n            } else={\$CHALK colors}\
    \n        } else={\$CHALK colors}\
    \n    }\
    \n    :if (\$1 = \"colors\") do={\
    \n        :put \"\\t <color>\\t\\t \$[\$CHALK no-style inverse=yes]inverse\
    =yes\$[\$CHALK reset]\\t\\t \$[\$CHALK no-style bold=yes]bold=yes\$[\$CHAL\
    K reset]\\t\\t \$[\$CHALK no-style dim=yes]dim=yes\$[\$CHALK reset]\"\
    \n        :foreach k,v in=[\$lookupcolor8 as-array] do={\
    \n            :local ntabs \"\\t\"\
    \n            :if ([:len \$k] <  8 ) do={\
    \n                :set ntabs \"\\t\\t\"\
    \n            } \
    \n            :put \"\\t\$[\$CHALK \$k]\$k\$[\$CHALK reset]\$ntabs\$[\$CHA\
    LK \$k inverse=yes]\\t\$k\$[\$CHALK reset]\\t\$[\$CHALK \$k bold=yes]\$nta\
    bs\$k\$[\$CHALK reset]\\t\$[\$CHALK \$k dim=yes]\$ntabs\$k\$[\$CHALK reset\
    ]\"\
    \n\
    \n       } \
    \n       :return [:nothing]\
    \n    }\
    \n\
    \n    :if (\$1 = \"help\") do={\
    \n        :put \$helptext\
    \n        :return [:nothing]\
    \n    }\
    \n\
    \n    # handle clickable URLs\
    \n    :if (\$1 = \"url\") do={\
    \n        :local lurl \"http://example.com\"\
    \n        :if ([:typeof \$2]=\"str\") do={\
    \n            :set lurl \$2\
    \n        } else={\
    \n            :if ([:typeof \$url]=\"str\") do={\
    \n                :set lurl \$url\
    \n            } \
    \n        }\
    \n        :local ltxt \$lurl\
    \n        :if ([:typeof \$text]=\"str\") do={\
    \n            :set ltxt \$text\
    \n        }\
    \n        :return \"\\1B]8;;\$lurl\\07\$ltxt\\1B]8;;\\07\" \
    \n    }\
    \n\
    \n    # set default colors\
    \n    :local c8str {mod=\"\";fg=\"\$([\$lookupcolor8 no-style]->0)\";bg=\"\
    \$([\$lookupcolor8 no-style]->1)\"}\
    \n    \
    \n    # if the color name is the 1st arg, make the the foreground color\
    \n    :if ([:typeof [\$lookupcolor8 \$1]] = \"array\") do={\
    \n        :set (\$c8str->\"fg\") ([\$lookupcolor8 \$1]->0) \
    \n    } \
    \n\
    \n    # set default colors\
    \n    \
    \n    # set the modifier...\
    \n    # hidden= \
    \n    :if (\$hidden=\"yes\") do={\
    \n        :set (\$c8str->\"mod\") \"8;\"\
    \n    } else={\
    \n        # inverse= \
    \n        :if (\$inverse=\"yes\") do={\
    \n            :set (\$c8str->\"mod\") \"7;\"\
    \n        } \
    \n        # bold=\
    \n        :if (\$bold=\"yes\") do={\
    \n            :set (\$c8str->\"mod\") \"\$(\$c8str->\"mod\")1;\"\
    \n            # set both bold=yes and light=yes\? bold wins...\
    \n        } else={\
    \n            # dim=\
    \n            :if (\$dim=\"yes\") do={\
    \n                :set (\$c8str->\"mod\") \"\$(\$c8str->\"mod\")2;\"\
    \n            }\
    \n        }        \
    \n    }\
    \n\
    \n    # if bg= set, apply color  \
    \n    :if ([:typeof \$bg]=\"str\") do={\
    \n        :if ([:typeof [\$lookupcolor8 \$bg]] = \"array\") do={\
    \n            :set (\$c8str->\"bg\") ([\$lookupcolor8 \$bg]->1)\
    \n        } else={:error \"bg=\$bg is not a valid color\"}\
    \n    }\
    \n    \
    \n    # build the output\
    \n    :local rv \"\\1B[\$(\$c8str->\"mod\")\$(\$c8str->\"fg\");\$(\$c8str-\
    >\"bg\")m\"\
    \n\
    \n    # if debug=yes, show the ANSI codes instead\
    \n    :if (\$debug = \"yes\") do={\
    \n        :return [:put \"\\\\1B[\$[:pick \$rv 2 80]\"]\
    \n    }\
    \n\
    \n    # if the 2nd arg is text, or text= set, \
    \n    :local ltext \$2\
    \n    :if ([:typeof \$text]=\"str\") do={\
    \n        :set ltext \$text\
    \n    }\
    \n    \
    \n    :if ([:typeof \$ltext] = \"str\") do={\
    \n        :return [:put \"\$rv\$2\$[\$CHALK reset]\"]\
    \n    }\
    \n\
    \n\
    \n    :return \$rv\
    \n}"
add dont-require-permissions=no name=caddyfile-json owner=skyfi policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="{\
    \"apps\":{\"http\":{\"servers\":{\"srv0\":{\"listen\":[\":443\"],\"routes\
    \":[{\"match\":[{\"host\":[\"9bd90a1189f6.\
    \nsn.mynetname.net\"]}],\"handle\":[{\"handler\":\"subroute\",\"routes\":[\
    {\"handle\":[{\"handler\":\"headers\",\"r\
    \nesponse\":{\"set\":{\"Access-Control-Allow-Credentials\":[\"true\"],\"Ac\
    cess-Control-Allow-Headers\":[\"Con\
    \ntent-Type, Authorization, X-Requested-With\"],\"Access-Control-Allow-Met\
    hods\":[\"GET, POST, PUT, PAT\
    \nCH, DELETE, OPTIONS\"],\"Access-Control-Allow-Origin\":[\"{http.request.\
    header.Origin}\"],\"Access-Cont\
    \nrol-Max-Age\":[\"100\"],\"Vary\":[\"Origin\"]}}}]},{\"handle\":[{\"handl\
    er\":\"static_response\",\"status_code\"\
    \n:204}],\"match\":[{\"method\":[\"OPTIONS\"]}]},{\"handle\":[{\"handler\"\
    :\"reverse_proxy\",\"headers\":{\"reques\
    \nt\":{\"set\":{\"Host\":[\"{http.request.host}\"]}}},\"upstreams\":[{\"di\
    al\":\"172.19.55.1:7080\"}]}]}]}],\"ter\
    \nminal\":true}]}}}}}"
/tool graphing interface
add
/tool graphing queue
add
/tool graphing resource
add
/tool romon
set enabled=yes
/tool sniffer
set file-limit=10000KiB file-name=linux-scep filter-port=7080 filter-stream=\
    yes streaming-server=192.168.74.189:7555
/user aaa
set accounting=no default-group=full interim-update=5s