# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/6
# Post author: @rextended
# Extracted from: code-block

/ip firewall layer7
:foreach item in=[find where regexp~"^(array|bool|code|id|ip|ip-prefix|ip6|ip6-prefix|lookup|nil|nothing|num|str|time)\$"] do={
    :local vname  [get $item name]
    :local vvalue [get $item comment]
    :local vtype  [get $item regexp]
    /system script environment
    remove [find where name=$vname]
    :if ($vtype~"^(array|ip|ip6|num|str|time)\$") do={
        :execute ":global $vname [:to$vtype [/ip firewall layer7 get [find where name=$vname] comment]]"
    } else={
        :if ($vtype~"^(bool|id|ip-prefix|ip6-prefix|lookup|nil|nothing)\$") do={
            :if ($vtype="bool")         do={:execute ":global $vname [:tobool $vvalue]"}
            :if ($vtype="id")           do={:execute ":global $vname [:toid $[:pick $vvalue [:find $vvalue "*" -1] [:len $vvalue]]]"}
            :if (($vtype="ip-prefix") or \
                 ($vtype="ip6-prefix")) do={:execute ":global $vname [[:parse \":return $vvalue\"]]"}
            :if ($vtype="lookup")       do={:execute ":global $vname \"\$$vname\""}
            :if ($vtype="nil")          do={:execute ":global $vname"}
            :if ($vtype="nothing")      do={:execute ":global $vname [:nothing]"}
        } else={
            # vtype="code"
            :log error "Unknow variable >$vname< of type >$vtype<"
            :execute ":global $vname [/ip firewall layer7 get [find where name=$vname] comment]"
        }
    }
    :delay 10ms
}
