# Source: https://forum.mikrotik.com/t/error-in-gateway-non-zero-ip-address-expected-when-using-quick-set/181665/12
# Topic: "Error in Gateway - non zero ip address expected!" when using Quick Set
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface bridge
                       add name=bridge disabled=no auto-mac=yes protocol-mode=rstp comment=defconf;
                     :local bMACIsSet 0;
                     :foreach k in=[/interface find where !(slave=yes   || name="ether1" || passthrough=yes   || name="ether1" || name~"bridge")] do={
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
