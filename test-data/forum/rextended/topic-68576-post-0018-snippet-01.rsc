# Source: https://forum.mikrotik.com/t/i-did-it-script-to-compute-unix-time/68576/18
# Post author: @rextended
# Extracted from: code-block

:global chr2lcase do={
    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }
    :local chrValue [:find $charsString $1 -1]
    :if (($chrValue > 64) and ($chrValue < 91)) do={
        :return [:pick $charsString ($chrValue + 32) ($chrValue + 33)]
    } else={
        :return $1
    }
}

:global chr2ucase do={
    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }
    :local chrValue [:find $charsString $1 -1]
    :if (($chrValue > 96) and ($chrValue < 123)) do={
        :return [:pick $charsString ($chrValue - 32) ($chrValue - 31)]
    } else={
        :return $1
    }
}
