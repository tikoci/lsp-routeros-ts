# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/4
# Post author: @rextended
# Extracted from: code-block

:global base64dec do={
    :local input   [:tostr "$1"]
    :local options "$2$3$4"

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    # RFC 4648 base64 Standard
    :local arrb64 [:toarray "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z\
                            ,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z\
                            ,0,1,2,3,4,5,6,7,8,9,+,/,="]
    :if ($options~"url") do={
        # RFC 4648 base64url URL and filename-safe standard
        :set arrb64 [:toarray "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z\
                              ,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z\
                              ,0,1,2,3,4,5,6,7,8,9,-,_,="]
    }

    :if ($options~"mustpad") do={
        :if (([:len $input] % 4) != 0) do={:error "Invalid length, must be padded with one or more ="}
    }

    :if ($options~"ignoreotherchr") do={
        :local position 0
        :local tmpchar   ""
        :local tmpstring ""
        :while ($position < [:len $input]) do={
            :set tmpchar [:pick $input $position ($position + 1)]
            :if ([:typeof [:find $arrb64 $tmpchar]] != "nil") do={:set tmpstring "$tmpstring$tmpchar"}
            :set position ($position + 1)
        }
        :set input $tmpstring
    }

    :local position 0
    :local output   "" ; :local work ""
    :local v1 0 ; :local v2 0 ; :local v3 0 ; :local v4 0 ; :local fchr "" ; :local schr "" ; :local tchr ""
    :while ($position < [:len $input]) do={
        :set work [:pick $input $position ($position + 4)]
        :set v1 [:find $arrb64 [:pick $work 0 1]]
        :set v2 [:find $arrb64 [:pick $work 1 2]]
        :set v3 [:find $arrb64 [:pick $work 2 3]]
        :set v4 [:find $arrb64 [:pick $work 3 4]]
        :if (([:typeof $v1] = "nil") or ([:typeof $v2] = "nil") or ([:typeof $v3] = "nil") or ([:typeof $v4] = "nil")) do={
            :error "Unexpected character, invalid Base64 sequence"
        }
        :if ([:typeof [:pick $work 1 2]] = "nil") do={
            :if ($options~"ignoreotherchr") do={:set v2 64 ; :set v3 64 ; :set v4 64} else={:error "Required 2nd character is missing"}
        }
        :if (([:typeof [:pick $work 2 3]] = "nil") and (($v2 & 15) != 0)) do={
            :if ($options~"ignoreotherchr") do={:set v3 64 ; :set v4 64} else={:error "Required 3rd character is missing"}
        }
        :if (([:typeof [:pick $work 3 4]] = "nil") and (($v3 &  3) != 0)) do={
            :if ($options~"ignoreotherchr") do={:set v4 64} else={:error "Required 4th character is missing"}
        }
        :set fchr [:pick $charsString  (($v1 << 2)       + ($v2 >> 4))]
        :set schr [:pick $charsString ((($v2 & 15) << 4) + ($v3 >> 2))]
        :set tchr [:pick $charsString ((($v3 &  3) << 6) +  $v4     ) ]
        :if ($v4 = 64) do={:set tchr "" ; :set position [:len $input]}
        :if ($v3 = 64) do={:set schr "" ; :set position [:len $input]}
        :if ($v2 = 64) do={:set fchr "" ;
                               :if ($options~"ignoreotherchr") do={
                                   :set position [:len $input]
                               } else={
                                   :error "Unexpected padding character ="
                               }
                          }
        :set output   "$output$fchr$schr$tchr"
        :set position ($position + 4)
    }
    :return $output
}
