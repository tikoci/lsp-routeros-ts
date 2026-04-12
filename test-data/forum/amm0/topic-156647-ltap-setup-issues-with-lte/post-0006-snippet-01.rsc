# Source: https://forum.mikrotik.com/t/ltap-setup-issues-with-lte/156647/6
# Topic: LtAP setup issues with LTE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# sep/ 2/2020  3: 9:38 by RouterOS 7.1.3
# software id = ZFR6-6BCM
#
            script: #| Welcome to RouterOS!
                    #|    1) Set a strong router password in the System > Users menu
                    #|    2) Upgrade the software in the System > Packages menu
                    #|    3) Enable firewall on untrusted networks
                    #|    4) Set your country name to observe wireless regulations
                    #| -----------------------------------------------------------------------------
                    #| WISP Bridge:
                    #|  * wireless and LAN interfaces are bridged;
                    #| wlan1 Configuration:
                    #|     mode:                ap-bridge;
                    #|     band:                2ghz-b/g/n;
                    #|     tx-chains:           0;1;
                    #|     rx-chains:           0;1;
                    #|     installation:        outdoor;
                    #|     wpa2:      no;
                    #|     ht-extension:        20/40mhz-XX;
                    #| LAN Configuration:
                    #|     DHCP Client: enabled on bridge (LAN port);
                    
                    :global ssid;
                    :global defconfMode;
                    :log info "Starting defconf script";
                    #-------------------------------------------------------------------------------
                    # Apply configuration.
                    # these commands are executed after installation or configuration reset
                    #-------------------------------------------------------------------------------
                    :if ($action = "apply") do={
                      # wait for interfaces
                      :local count 0;
                      :while ([/interface ethernet find] = "") do={
                        :if ($count = 30) do={
                          :log warning "DefConf: Unable to find ethernet interfaces";
                          /quit;
                        }
                        :delay 1s; :set count ($count +1); 
                      };
                      :local count 0;
                      :while ([/interface wireless print count-only] < 1) do={ 
                        :set count ($count +1);
                        :if ($count = 40) do={
                          :log warning "DefConf: Unable to find wireless interface(s)"; 
                          /ip address add address=192.168.88.1/24 interface=ether1 comment="defconf";
                          /quit
                        }
                        :delay 1s;
                      };
                      /interface wireless {
                    :local ifcId [/interface wireless find where default-name=wlan1]
                    :local currentName [/interface wireless get $ifcId name]
                        set $ifcId mode=ap-bridge band=2ghz-b/g/n disabled=no wireless-protocol=any \
                           distance=dynamic installation=outdoor
                        set $ifcId channel-width=20/40mhz-XX;
                        set $ifcId frequency=auto
                        :local wlanMac  [/interface wireless get $ifcId mac-address];
                        :set ssid "MikroTik-$[:pick $wlanMac 9 11]$[:pick $wlanMac 12 14]$[:pick $wlanMac 15 17]"
                        set $ifcId ssid=$ssid
                      }
                     /interface bridge
                       add name=bridge disabled=no auto-mac=yes protocol-mode=rstp comment=defconf;
                     :local bMACIsSet 0;
                     :foreach k in=[/interface find where !(slave=yes   || name~"bridge")] do={
                       :local tmpPortName [/interface get $k name];
                       :if ($bMACIsSet = 0) do={
                         :if ([/interface get $k type] = "ether") do={
                           /interface bridge set "bridge" auto-mac=no admin-mac=[/interface get $tmpPortName mac-address];
                           :set bMACIsSet 1;
                         }
                       }
                         :if (([/interface get $k type] != "ppp-out") && ([/interface get $k type] != "lte")) do={
                           /interface bridge port
                             add bridge=bridge interface=$tmpPortName comment=defconf;
                         }
                       }
                      /ip dhcp-client add interface=bridge disabled=no comment="defconf";
                    }
                    #-------------------------------------------------------------------------------
                    # Revert configuration.
                    # these commands are executed if user requests to remove default configuration
                    #-------------------------------------------------------------------------------
                    :if ($action = "revert") do={
                    /user set admin password=""
                     /system routerboard mode-button set enabled=no
                     /system routerboard mode-button set on-event=""
                     /system script remove [find comment~"defconf"]
                     /ip firewall filter remove [find comment~"defconf"]
                     /ipv6 firewall filter remove [find comment~"defconf"]
                     /ipv6 firewall address-list remove [find comment~"defconf"]
                     /ip firewall nat remove [find comment~"defconf"]
                     /interface list member remove [find comment~"defconf"]
                     /interface detect-internet set detect-interface-list=none
                     /interface detect-internet set lan-interface-list=none
                     /interface detect-internet set wan-interface-list=none
                     /interface detect-internet set internet-interface-list=none
                     /interface list remove [find comment~"defconf"]
                     /tool mac-server set allowed-interface-list=all
                     /tool mac-server mac-winbox set allowed-interface-list=all
                     /ip neighbor discovery-settings set discover-interface-list=!dynamic
                       :local o [/ip dhcp-server network find comment="defconf"]
                       :if ([:len $o] != 0) do={ /ip dhcp-server network remove $o }
                       :local o [/ip dhcp-server find name="defconf" !disabled]
                       :if ([:len $o] != 0) do={ /ip dhcp-server remove $o }
                       /ip pool {
                         :local o [find name="default-dhcp" ranges=192.168.88.10-192.168.88.254]
                         :if ([:len $o] != 0) do={ remove $o }
                       }
                       :local o [/ip dhcp-client find comment="defconf"]
                       :if ([:len $o] != 0) do={ /ip dhcp-client remove $o }
                     /ip dns {
                       set allow-remote-requests=no
                       :local o [static find comment="defconf"]
                       :if ([:len $o] != 0) do={ static remove $o }
                     }
                     /ip address {
                       :local o [find comment="defconf"]
                       :if ([:len $o] != 0) do={ remove $o }
                     }
                     :foreach iface in=[/interface ethernet find] do={
                       /interface ethernet set $iface name=[get $iface default-name]
                     }
                     /interface bridge port remove [find comment="defconf"]
                     /interface bridge remove [find comment="defconf"]
                     /interface bonding remove [find comment="defconf"]
                     /interface wireless cap set enabled=no interfaces="" caps-man-addresses=""
                     /interface wireless reset-configuration wlan1
                     /interface wireless security-profile set default mode=none\
                          authentication-types="" disable-pmkid=no wpa2-pre-shared-key="" comment="" 
                      /caps-man manager set enabled=no
                      /caps-man manager interface remove [find comment="defconf"]
                      /caps-man manager interface set [ find default=yes ] forbid=no
                      /caps-man provisioning remove [find comment="defconf"]
                      /caps-man configuration remove [find comment="defconf"]
                    }
                    :log info Defconf_script_finished;
                    :set defconfMode;
                    :set ssid;
                    
  caps-mode-script: #-------------------------------------------------------------------------------
                    # Note: script will not execute at all (will throw a syntax error) if
                    #       dhcp or wireless-fp packages are not installed
                    #-------------------------------------------------------------------------------
                    
                    #| CAP configuration
                    #|
                    #|   Wireless interfaces are set to be managed by CAPsMAN.
                    #|   All ethernet interfaces and CAPsMAN managed interfaces are bridged.
                    #|   DHCP client is set on bridge interface.
                    
                    # bridge port name
                    :global brName  "bridgeLocal";
                    :global logPref "defconf:";
                    
                    
                    :global action;
                    
                    :log info $action
                    
                    :if ($action = "apply") do={
                    
                      # wait for ethernet interfaces
                      :local count 0;
                      :while ([/interface ethernet find] = "") do={
                        :if ($count = 30) do={
                          :log warning "DefConf: Unable to find ethernet interfaces";
                          /quit;
                        }
                        :delay 1s; :set count ($count + 1);
                      }
                    
                      :local macSet 0;
                      :local tmpMac "";
                    
                      :foreach k in=[/interface ethernet find] do={
                        # first ethernet is found; add bridge and set mac address of the ethernet port
                        :if ($macSet = 0) do={
                          :set tmpMac [/interface ethernet get $k mac-address];
                          /interface bridge add name=$brName auto-mac=no admin-mac=$tmpMac comment="defconf";
                          :set macSet 1;
                        }
                        # add bridge ports
                        /interface bridge port add bridge=$brName interface=$k comment="defconf"
                      }
                    
                      # try to add dhcp client on bridge interface (may fail if already exist)
                      :do {
                        /ip dhcp-client add interface=$brName disabled=no comment="defconf"
                      } on-error={ :log warning "$logPref unable to add dhcp client";}
                    
                    
                      # try to configure caps (may fail if for example specified interfaces are missing)
                      :local interfacesList "";
                      :local bFirst 1;
                    
                      # wait for wireless interfaces
                      :while ([/interface wireless find] = "") do={
                        :if ($count = 30) do={
                          :log warning "DefConf: Unable to find wireless interfaces";
                          /quit;
                        }
                        :delay 1s; :set count ($count + 1);
                      }
                    
                      # delay just to make sure that all wireless interfaces are loaded
                      :delay 5s;
                      :foreach i in=[/interface wireless find] do={
                        if ($bFirst = 1) do={
                          :set interfacesList [/interface wireless get $i name];
                          :set bFirst 0;
                        } else={
                          :set interfacesList "$interfacesList,$[/interface wireless get $i name]";
                        }
                      }
                      :do {
                        /interface wireless cap
                          set enabled=yes interfaces=$interfacesList discovery-interfaces=$brName bridge=$brName
                      } on-error={ :log warning "$logPref unable to configure caps";}
                    
                    }
                    
                    :if ($action = "revert") do={
                      :do {
                        /interface wireless cap
                          set enabled=no interfaces="" discovery-interfaces="" bridge=none
                      } on-error={ :log warning "$logPref unable to unset caps";}
                    
                      :local o [/ip dhcp-client find comment="defconf"]
                      :if ([:len $o] != 0) do={ /ip dhcp-client remove $o }
                    
                      /interface bridge port remove [find comment="defconf"]
                      /interface bridge remove [find comment="defconf"]
                    
                    }
     custom-script:
