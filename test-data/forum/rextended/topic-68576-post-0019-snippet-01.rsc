# Source: https://forum.mikrotik.com/t/i-did-it-script-to-compute-unix-time/68576/19
# Post author: @rextended
# Extracted from: code-block

:global str2case do={
    :local input   [:tostr "$1"]
    :local options "$2"
    :local letters "[A-Za-z]"

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    :local position 0 ; :local chrValue 0; :local what "U" ; :local output "" ; :local work "" ; :local previous ""
    :while ($position < [:len $input]) do={
        :set work     [:pick $input $position ($position + 1)]
        :set chrValue [:find $charsString $work -1]
        :if ($options~"(p|P)") do={:set what "U"}
        :if (($options~"(l|L)") or ((!($options~"(l|L|u|U)")) and ($previous~$letters))) do={:set what "L"}
        :if (($what = "L") and (($chrValue > 64) and ($chrValue <  91))) do={
            :set work [:pick $charsString ($chrValue + 32) ($chrValue + 32 + 1)]
        }
        :if (($what = "U") and (($chrValue > 96) and ($chrValue < 123))) do={
            :set work [:pick $charsString ($chrValue - 32) ($chrValue - 32 + 1)]
        }
        :set output   "$output$work"
        :set previous $work
        :set position ($position + 1)
    }
    :return $output
}
