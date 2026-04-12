# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/56
# Post author: @rextended
# Extracted from: code-block

:global gsm7topdu do={
    :local input   [:tostr "$1"]
    :local options "$2"

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
    :local v1 0 ; :local v2 0 ; :local v3 0 ; :local v4 0 ; :local v5 0 ; :local v6 0 ; :local v7 0 ; :local v8 0
    :local ch1 "" ; :local ch2 "" ; :local ch3 "" ; :local ch4 "" ; :local ch5 "" ; :local ch6 "" ; :local ch7 ""

    :while ($position < [:len $input]) do={
        :set work [:pick $input $position ($position + 8)]
        :set v1 [$chr2int [:pick $work 0 1] $charsString]
        :set v2 [$chr2int [:pick $work 1 2] $charsString]
        :set v3 [$chr2int [:pick $work 2 3] $charsString]
        :set v4 [$chr2int [:pick $work 3 4] $charsString]
        :set v5 [$chr2int [:pick $work 4 5] $charsString]
        :set v6 [$chr2int [:pick $work 5 6] $charsString]
        :set v7 [$chr2int [:pick $work 6 7] $charsString]
        :set v8 [$chr2int [:pick $work 7 8] $charsString]

        :if (($v1 > 0x7F) or ($v2 > 0x7F) or ($v3 > 0x7F) or ($v4 > 0x7F) or \
             ($v5 > 0x7F) or ($v6 > 0x7F) or ($v7 > 0x7F) or ($v8 > 0x7F)) do={
            :error "Unexpected 8-bit character value"
        }

        :set ch1 [$numbyte2hex ((($v2 & 0x01) << 7) +  $v1      ) ]
        :set ch2 [$numbyte2hex ((($v3 & 0x03) << 6) + ($v2 >> 1)) ]
        :set ch3 [$numbyte2hex ((($v4 & 0x07) << 5) + ($v3 >> 2)) ]
        :set ch4 [$numbyte2hex ((($v5 & 0x0F) << 4) + ($v4 >> 3)) ]
        :set ch5 [$numbyte2hex ((($v6 & 0x1F) << 3) + ($v5 >> 4)) ]
        :set ch6 [$numbyte2hex ((($v7 & 0x3F) << 2) + ($v6 >> 5)) ]
        :set ch7 [$numbyte2hex ((($v8 & 0x7F) << 1) + ($v7 >> 6)) ]

                 :if ([:len $work] = 8) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6$ch7"
        } else={ :if ([:len $work] = 7) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6$[$numbyte2hex ($v7 >> 6)]"
        } else={ :if ([:len $work] = 6) do={:set work "$ch1$ch2$ch3$ch4$ch5$ch6"
        } else={ :if ([:len $work] = 5) do={:set work "$ch1$ch2$ch3$ch4$ch5"
        } else={ :if ([:len $work] = 4) do={:set work "$ch1$ch2$ch3$ch4"
        } else={ :if ([:len $work] = 3) do={:set work "$ch1$ch2$ch3"
        } else={ :if ([:len $work] = 2) do={:set work "$ch1$ch2"
        } else={ :if ([:len $work] = 1) do={:set work "$ch1"
        }}}}}}}}

        :set output "$output$work"
        :set position ($position + 8)
    }

    :if ($options~"addlen") do={:set output "$[$numbyte2hex [:len $input]]$output"}

    :return $output
}
