# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/5
# Post author: @rextended
# Extracted from: code-block

:global str2base16 do={
    :local input   [:tostr "$1"]
    :local options [:tostr "$2"]

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    :local hexchars "0123456789ABCDEF"
    :if ($options~"lowercase") do={
        :set hexchars "0123456789abcdef"
    }
    :local chr2hex do={
        :local input [:find $2 $1 -1]
        :local convert [:pick $3 (($input >> 4) & 0xF)]
        :set convert ($convert.[:pick $3 ($input & 0xF)])
        :return $convert
    }

    :local position 0
    :local output   "" ; :local work ""
    :while ($position < [:len $input]) do={
        :set work [$chr2hex [:pick $input $position ($position + 1)] $charsString $hexchars]
        :set output   "$output$work"
        :set position ($position + 1)
    }
    :return $output
}
