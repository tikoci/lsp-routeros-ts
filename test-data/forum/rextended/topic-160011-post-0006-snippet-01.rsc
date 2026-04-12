# Source: https://forum.mikrotik.com/t/script-fails-to-create-file/160011/6
# Post author: @rextended
# Extracted from: code-block

{
:local interfaces "12.1_5g,12.1_ch1,12.2_ch1,12.3_ch6,12.4_ch11,12.5_ch11"
:local parentdir  "resziget" 

/file
:if ([:len [find where name="flash" and type="disk"]] = 1) do={:set parentdir "flash/$parentdir"}

/ip smb shares remove [find where name="temp"]
/ip smb shares add name="temp" directory=$parentdir

:foreach item in=[:toarray $interfaces] do={
    /ip smb shares remove [find where name="temp"]
    /ip smb shares add name=temp directory="$parentdir/$item"
    :local fname "$parentdir/$item/$item"
    :local logtx [:len [/caps-man registration-table find where interface=$item]]
    :put "file name: \"$fname.txt\" - add this content: \"<DATE> <TIME>: $logtx\""
}

/ip smb shares remove [find where name="temp"]
}
