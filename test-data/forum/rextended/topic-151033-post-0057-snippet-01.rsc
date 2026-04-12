# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/57
# Post author: @rextended
# Extracted from: code-block

:global pdutogsm7 do={
    :local input   [:tostr "$1"]
    :local options "$2$3"

    :if ($options~"skiplen") do={:set input [:pick $input 1 [:len $input]]}

    :local numbyte2hex do={
        :local input [:tonum $1]
        :local hexchars "0123456789ABCDEF"
        :local convert [:pick $hexchars (($input >> 4) & 0xF)]
        :set convert ($convert.[:pick $hexchars ($input & 0xF)])
        :return $convert
    }

    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    :local chr2int do={:if (($1="") or ([:len $1] > 1) or ([:typeof $1] = "nothing")) do={:return -1}; :return [:find $2 $1 -1]}

    :local position 0
    :local output "" ; :local work ""
    :local v1 0 ; :local v2 0 ; :local v3 0 ; :local v4 0 ; :local v5 0 ; :local v6 0 ; :local v7 0
    :local ch1 "" ; :local ch2 "" ; :local ch3 "" ; :local ch4 "" ; :local ch5 "" ; :local ch6 "" ; :local ch7 "" ; :local ch8 ""
    :local errorinvalid "Invalid PDU data, expected value not provided."

    :while ($position < [:len $input]) do={
        :set work [:pick $input $position ($position + 7)]
        :set v1 [$chr2int [:pick $work 0 1] $charsString]
        :set v2 [$chr2int [:pick $work 1 2] $charsString]
        :set v3 [$chr2int [:pick $work 2 3] $charsString]
        :set v4 [$chr2int [:pick $work 3 4] $charsString]
        :set v5 [$chr2int [:pick $work 4 5] $charsString]
        :set v6 [$chr2int [:pick $work 5 6] $charsString]
        :set v7 [$chr2int [:pick $work 6 7] $charsString]

        :if (!($options~"ignoreinvalid")) do={
            :if (([:len $work] = 1) and (($v1 >> 7) != 0)) do={:error $errorinvalid}
            :if (([:len $work] = 2) and (($v2 >> 6) != 0)) do={:error $errorinvalid}
            :if (([:len $work] = 3) and (($v3 >> 5) != 0)) do={:error $errorinvalid}
            :if (([:len $work] = 4) and (($v4 >> 4) != 0)) do={:error $errorinvalid}
            :if (([:len $work] = 5) and (($v5 >> 3) != 0)) do={:error $errorinvalid}
            :if (([:len $work] = 6) and (($v6 >> 2) != 0)) do={:error $errorinvalid}
        }

        :set ch1 [$numbyte2hex (  $v1                     & 0x7F) ]
        :set ch2 [$numbyte2hex ((($v2 << 1) + ($v1 >> 7)) & 0x7F) ]
        :set ch3 [$numbyte2hex ((($v3 << 2) + ($v2 >> 6)) & 0x7F) ]
        :set ch4 [$numbyte2hex ((($v4 << 3) + ($v3 >> 5)) & 0x7F) ]
        :set ch5 [$numbyte2hex ((($v5 << 4) + ($v4 >> 4)) & 0x7F) ]
        :set ch6 [$numbyte2hex ((($v6 << 5) + ($v5 >> 3)) & 0x7F) ]
        :set ch7 [$numbyte2hex ((($v7 << 6) + ($v6 >> 2)) & 0x7F) ]
        :set ch8 [$numbyte2hex ((              $v7 >> 1)  & 0x7F) ]

                 :if (([:len $work] = 7) and ($ch8 != "00")) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6$ch7$ch8"
        } else={ :if ( [:len $work] = 7                    ) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6$ch7"
        } else={ :if ( [:len $work] = 6                    ) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6"
        } else={ :if ( [:len $work] = 5                    ) do={:set work "$ch1$ch2$ch3$ch4$ch5"
        } else={ :if ( [:len $work] = 4                    ) do={:set work "$ch1$ch2$ch3$ch4"
        } else={ :if ( [:len $work] = 3                    ) do={:set work "$ch1$ch2$ch3"
        } else={ :if ( [:len $work] = 2                    ) do={:set work "$ch1$ch2"
        } else={ :if ( [:len $work] = 1                    ) do={:set work "$ch1"
        }}}}}}}}

        :set output "$output$work"
        :set position ($position + 7)
    }

    :return $output
}
