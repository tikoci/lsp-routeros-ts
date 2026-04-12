# Source: https://forum.mikrotik.com/t/multi-wan-both-on-dhcp/154290/17
# Topic: Multi WAN both on DHCP
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ($bound=1) do={
  /ip route set [find where comment~"Monitor ISP2"] gateway=$"gateway-address" disabled=no
  /ip firewall mangle set [find comment~"Monitor ISP2"] disabled=no dst-address=$"gateway-address"
} else={
  /ip route set [find where comment~"Monitor ISP2"] disabled=yes
  /ip firewall mangle set [find where comment~"Monitor ISP2"] disabled=yes
}
