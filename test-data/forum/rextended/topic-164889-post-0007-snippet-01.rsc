# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/7
# Post author: @rextended
# Extracted from: code-block

:global str2base32 do={
    :local input   [:tostr "$1"]
    :local options "$2$3"

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    :local chr2int do={:if (($1="") or ([:len $1] > 1) or ([:typeof $1] = "nothing")) do={:return -1}; :return [:find $2 $1 -1]}

    # RFC 4648 base32 Standard
    :local arrb32 [:toarray "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7,="]
    :if ($options~"hex") do={
        # RFC 4648 base32 Extended Hex Alphabet
        :set arrb32 [:toarray "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,="]
    }
    :if ($options~"nopad") do={:set ($arrb32->32) ""}

    :local position 0
    :local output   "" ; :local work ""
    :local v1 "" ; :local v2 "" ; :local v3 "" ; :local v4 "" ; :local v5 ""
    :local fir5bit 0 ; :local sec5bit 0 ; :local thi5bit 0 ; :local qua5bit 0
    :local fif5bit 0 ; :local six5bit 0 ; :local sep5bit 0 ; :local eig5bit 0
    :while ($position < [:len $input]) do={
        :set work [:pick $input $position ($position + 5)]
        :set v1 [$chr2int [:pick $work 0 1] $charsString]
        :set v2 [$chr2int [:pick $work 1 2] $charsString]
        :set v3 [$chr2int [:pick $work 2 3] $charsString]
        :set v4 [$chr2int [:pick $work 3 4] $charsString]
        :set v5 [$chr2int [:pick $work 4 5] $charsString]

        :set fir5bit   ($v1 >> 3)
        :set sec5bit ((($v1 &  7) *  4) + ($v2 >> 6))
        :set thi5bit  (($v2 >> 1) & 31)
        :set qua5bit ((($v1 &  1) * 16) + ($v3 >> 4))
        :set fif5bit ((($v3 & 15) *  2) + ($v4 >> 7))
        :set six5bit  (($v4 >> 2) & 31)
        :set sep5bit ((($v4 &  3) *  8) + ($v5 >> 5))
        :set eig5bit   ($v5 & 31)

        :if ([:len $work] < 2) do={:set thi5bit 32 ; :set qua5bit 32}
        :if ([:len $work] < 3) do={:set fif5bit 32                 }
        :if ([:len $work] < 4) do={:set six5bit 32 ; :set sep5bit 32}
        :if ([:len $work] < 5) do={:set eig5bit 32                 }

        :set output   "$output$($arrb32->$fir5bit)$($arrb32->$sec5bit)$($arrb32->$thi5bit)$($arrb32->$qua5bit)"
        :set output   "$output$($arrb32->$fif5bit)$($arrb32->$six5bit)$($arrb32->$sep5bit)$($arrb32->$eig5bit)"
        :set position ($position + 5)
    }
    :return $output
}
