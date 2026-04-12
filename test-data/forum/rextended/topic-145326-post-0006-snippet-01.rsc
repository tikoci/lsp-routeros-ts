# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/6
# Post author: @rextended
# Extracted from: code-block

/system script environment
:foreach item in=[find] do={
    :local vname  [get $item name]
    :local vvalue [get $item value]
    :if ($vvalue~"^\\*") do={:set vvalue "ID$vvalue"}
    :if ($vvalue~"^(\\(code\\)|;\?\\(eva\?l )") do={:set vvalue "(code)"}
    /ip firewall layer7
    remove [find where name=$vname]
    add name=$vname comment="$vvalue"
    :delay 10ms
    :execute "/ip firewall layer7 set [find where name=$vname] regexp=[:typeof \$$vname]"
    :if ($vvalue="(code)") do={:delay 10ms ; set [find where name=$vname] regexp="code"}
}
