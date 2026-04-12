# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/18
# Post author: @rextended
# Extracted from: code-block

:global UCS2toUTF8 do={
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

    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local output ""

    :local lenstr [:len $string]
    :for pos from=0 to=($lenstr - 1) step=2 do={
       :local input (([$chr2int [:pick $string  $pos      ($pos + 1)] $charsString] * 0x100) + \
                     ([$chr2int [:pick $string ($pos + 1) ($pos + 2)] $charsString]        ))
        :local results [:toarray ""]
        :local utf   ""
        :if ($input > 0x7F) do={
            :if ($input > 0x7FF) do={
                :if ($input > 0xFFFF) do={
                    :if ($input > 0x10FFFF) do={
                        :error "UTF-8 do not have code point > of 0x10FFFF"
                    } else={
                        :error "UCS-2 do not have code point > of 0xFFFF"
# the following commented lines are not used on UCS-2
# but I have already prepared my script for future changes to work with all UNICODE code points from 0x000000 to 0x10FFFF as well...
#                        :set ($results->0) (0xF0 + ( $input >> 18        ))
#                        :set ($results->1) (0x80 + (($input >> 12) & 0x3F))
#                        :set ($results->2) (0x80 + (($input >>  6) & 0x3F))
#                        :set ($results->3) (0x80 + ( $input        & 0x3F))
                    }
                } else={
                    :set ($results->0) (0xE0 + ( $input >> 12        ))
                    :set ($results->1) (0x80 + (($input >>  6) & 0x3F))
                    :set ($results->2) (0x80 + ( $input        & 0x3F))
                }
            } else={
                :set ($results->0) (0xC0 + ($input >>    6))
                :set ($results->1) (0x80 + ($input  & 0x3F))
            }
        } else={
            :set ($results->0) $input
        }
        :foreach item in=$results do={
            :set utf "$utf%$[$numbyte2hex $item]"
        }
        :set output "$output$utf"
    }
    :return $output
}
