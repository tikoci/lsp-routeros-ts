# Source: https://forum.mikrotik.com/t/dual-wan-failover-script-ping-command/150516/27
# Post author: @rextended
# Extracted from: code-block

:global something

:if ([:len [/ip route find where comment="ISP2" and active=yes]] > 0) do={
    :if ($something != true) do={
        /ip fire conn
        :foreach idc in=[find where timeout>60] do={ remove [find where .id=$idc] }
        :set something true
    }
} else={
    :if ($something != false) do={
        /ip fire conn
        :foreach idc in=[find where timeout>60] do={ remove [find where .id=$idc] }
        :set something false
    }
}
