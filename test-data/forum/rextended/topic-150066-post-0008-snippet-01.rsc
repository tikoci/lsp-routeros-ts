# Source: https://forum.mikrotik.com/t/crs-vlan-add-untagged-interfaces-via-script/150066/8
# Post author: @rextended
# Extracted from: code-block

{
    /interface ethernet
    :local InterfaceList ""
    :local separator ""
    :foreach i,Interface in=[ find where default-name~"(combo|ether|sfp)*" ] do={
        :set InterfaceList "$InterfaceList$separator$[ get $Interface name ]"
        :if ($i = 0) do={ :set separator "," }
    }

    :log info $InterfaceList
}
