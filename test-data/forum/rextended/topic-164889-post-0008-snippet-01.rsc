# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/8
# Post author: @rextended
# Extracted from: code-block

:global base32dec do={
    :local input   [:tostr "$1"]
    :local options "$2$3"

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    # RFC 4648 base32 Standard
    :local arrb32 [:toarray "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7,="]
    :if ($options~"hex") do={
        # RFC 4648 base32 Extended Hex Alphabet
        :set arrb32 [:toarray "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,="]
    }

    :if ($options~"mustpad") do={
        :if (([:len $input] % 8) != 0) do={:error "Invalid length, must be padded with one or more ="}
    }

    :local position 0
    :local output   "" ; :local work ""
    :local v1 0 ; :local v2 0 ; :local v3 0 ; :local v4 0 ; :local v5 0 ; :local v6 0 ; :local v7 0 ; :local v8 0
    :local firchr "" ; :local secchr "" ; :local thichr "" ; :local quachr "" ; :local fifchr ""
    :while ($position < [:len $input]) do={
        :set work [:pick $input $position ($position + 8)]
        :set v1 [:find $arrb32 [:pick $work 0 1]]
        :set v2 [:find $arrb32 [:pick $work 1 2]]
        :set v3 [:find $arrb32 [:pick $work 2 3]]
        :set v4 [:find $arrb32 [:pick $work 3 4]]
        :set v5 [:find $arrb32 [:pick $work 4 5]]
        :set v6 [:find $arrb32 [:pick $work 5 6]]
        :set v7 [:find $arrb32 [:pick $work 6 7]]
        :set v8 [:find $arrb32 [:pick $work 7 8]]
        :if (([:typeof $v1] = "nil") or ([:typeof $v2] = "nil") or ([:typeof $v3] = "nil") or ([:typeof $v4] = "nil") or \
             ([:typeof $v5] = "nil") or ([:typeof $v6] = "nil") or ([:typeof $v7] = "nil") or ([:typeof $v8] = "nil")) do={
            :error "Unexpected character, invalid Base32 sequence"
        }

        :if (([:typeof [:pick $work 1 2]] = "nil") and ([:pick $work 0 1] != "=")) \
            do={:error "Required 2nd character is missing"}
        :if (([:typeof [:pick $work 2 3]] = "nil") and (($v2 & 3) != 0)) \
            do={:error "Required 3rd character is missing"}
        :if (([:typeof [:pick $work 3 4]] = "nil") and ((($v2 & 3) != 0) or ([:typeof [:pick $work 2 3]] != "nil"))) \
            do={:error "Required 4th character is missing"}
        :if (([:typeof [:pick $work 4 5]] = "nil") and (($v4 & 15) != 0)) \
            do={:error "Required 5th character is missing"}
        :if (([:typeof [:pick $work 5 6]] = "nil") and (($v5 & 1) != 0)) \
            do={:error "Required 6th character is missing"}
        :if (([:typeof [:pick $work 6 7]] = "nil") and ((($v5 & 1) != 0) or ([:typeof [:pick $work 5 6]] != "nil"))) \
            do={:error "Required 7th character is missing"}
        :if (([:typeof [:pick $work 7 8]] = "nil") and (($v7 & 7) != 0)) \
            do={:error "Required 8th character is missing"}

        :set firchr [:pick $charsString (( $v1       *   8)             + ($v2 >> 2))]
        :set secchr [:pick $charsString ((($v2 &  3) *  64) + ($v3 * 2) + ($v4 >> 4))]
        :set thichr [:pick $charsString ((($v4 & 15) *  16)             + ($v5 >> 1))]
        :set quachr [:pick $charsString ((($v5 &  1) * 128) + ($v6 * 4) + ($v7 >> 3))]
        :set fifchr [:pick $charsString ((($v7 &  7) *  32)             +  $v8      )]

        :if ($v1 != 32) do={
            :if (  $v2 = 32                                       ) do={:error "Unexpected padding character ="}
            :if ((($v3 = 32)  or ($v4 = 32)) and (($v2 &  3) != 0)) do={:error "Unexpected padding character ="}
            :if ( ($v4 = 32) and ($v3!= 32)                       ) do={:error "Unexpected padding character ="}
            :if (( $v5 = 32                ) and (($v4 & 15) != 0)) do={:error "Unexpected padding character ="}
            :if ((($v6 = 32)  or ($v7 = 32)) and (($v5 &  1) != 0)) do={:error "Unexpected padding character ="}
            :if ( ($v7 = 32) and ($v6!= 32)                       ) do={:error "Unexpected padding character ="}
            :if ( ($v8 = 32)                 and (($v7 &  7) != 0)) do={:error "Unexpected padding character ="}
        }

        :if ($v8 = 32) do={:set fifchr "" ; :set position [:len $input]}
        :if ($v7 = 32) do={:set quachr "" ; :set position [:len $input]}
        :if ($v6 = 32) do={:set quachr "" ; :set position [:len $input]}
        :if ($v5 = 32) do={:set thichr "" ; :set position [:len $input]}
        :if ($v4 = 32) do={:set thichr "" ; :set position [:len $input]}
        :if ($v3 = 32) do={:set secchr "" ; :set position [:len $input]}
        :if ($v2 = 32) do={:set firchr "" ; :set position [:len $input]}
        :if ($v1 = 32) do={:set firchr "" ; :set position [:len $input]}

        :set output   "$output$firchr$secchr$thichr$quachr$fifchr"
        :set position ($position + 8)
    }
    :return $output
}
