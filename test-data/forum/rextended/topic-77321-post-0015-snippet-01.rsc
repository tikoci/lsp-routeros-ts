# Source: https://forum.mikrotik.com/t/return-ip-octet-function/77321/15
# Post author: @rextended
# Extracted from: code-block

:global ip2array do={
    :local ip [:toip $1]
    :local array [:toarray ""]
    :if ([:typeof $ip] != "ip") do={:return $array}
    :set ($array->0) $ip
    :set ip [:tonum $ip]
    :set ($array->1) (($ip >> 24) & 255)
    :set ($array->2) (($ip >> 16) & 255)
    :set ($array->3) (($ip >>  8) & 255)
    :set ($array->4) ( $ip        & 255)
    :return $array
}
