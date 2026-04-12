# Source: https://forum.mikrotik.com/t/dual-wan-failover-script-ping-command/150516/25
# Post author: @rextended
# Extracted from: code-block

/ip fire conn
:foreach idc in=[find where timeout>60] do={
 remove [find where .id=$idc]
}
