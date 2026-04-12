# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/26
# Post author: @rextended
# Extracted from: code-block

:global UTF8toUCS2 do={
    :local repch "\FF\FD"
    :if ([:typeof $2] = "no-replace") do={:set repch ""}
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

    :local chr2int do={
        :if (($1="") or ([:len $1] > 1) or ([:typeof $1] = "nothing")) do={:return -1}
        :return [:find $2 $1 -1]
    }

    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local output ""

    :local lenstr [:len $string]
    :local read1; :local char1; :local char2; :local char3; :local char4; :local ucsvalue
    :local outstr ""
    :local pos 0
    :while ($pos < $lenstr) do={
        :set read1 [:pick $string $pos ($pos + 1)]
        :set char1 [$chr2int $read1 $charsString]
        :if ($char1 < 0x80) do={
            :set outstr "\00$read1"
        }
        :if ((($char1 > 0x7F) and ($char1 < 0xC2)) or ($char1 > 0xEF)) do={
            :set outstr $repch
        }
        :set char2 [$chr2int [:pick $string ($pos + 1) ($pos + 2)] $charsString]
        :if (($char1 > 0xC1) and ($char1 < 0xE0)) do={
            :if (($char2 < 0x80) or ($char2 > 0xBF)) do={
                :set outstr $repch
            } else={
                :set ucsvalue ((($char1 - 0xC0) * 0x40) + ($char2 - 0x80))
                :set outstr "$[:pick $charsString (($ucsvalue >> 8) & 0xFF)]$[:pick $charsString ($ucsvalue & 0xFF)]"
                :set pos ($pos + 1)
            }
        }
        :set char3 [$chr2int [:pick $string ($pos + 2) ($pos + 3)] $charsString]
        :if (($char1 > 0xDF) and ($char1 < 0xF0)) do={
            :if ((($char2 < 0x80) or ($char2 > 0xBF)) \
                 or ((($char1 = 0xE0) and ($char2 < 0xA0)) or (($char1 = 0xED) and ($char2 > 0x9F)))) do={
                :set outstr $repch
            } else={
                :if (($char3 < 0x80) or ($char3 > 0xBF)) do={
                    :set outstr $repch
                    :set pos ($pos + 1)
                } else={
                    :set ucsvalue ((($char1 - 0xE0) * 0x1000) + (($char2 - 0x80) * 0x40) + ($char3 - 0x80))
                    :set outstr "$[:pick $charsString (($ucsvalue >> 8) & 0xFF)]$[:pick $charsString ($ucsvalue & 0xFF)]"
                    :set pos ($pos + 2)
                }
            }
        }

# the following commented lines are not used on UCS-2
# but I have already prepared my script for future changes to work with all UNICODE code points from 0x000000 to 0x10FFFF as well...
#        :set char4 [$chr2int [:pick $string ($pos + 3) ($pos + 4)] $charsString]
#        :if (($char1 > 0xEF) and ($char1 < 0xF5)) do={
#            :if ((($char2 < 0x80) or ($char2 > 0xBF)) \
#                 or ((($char1 = 0xF0) and ($char2 < 0x90)) or (($char1 = 0xF4) and ($char2 > 0x8F)))) do={
#                :set outstr $repch
#            } else={
#                :if (($char3 < 0x80) or ($char3 > 0xBF)) do={
#                    :set outstr $repch
#                    :set pos ($pos + 1)
#                } else={
#                    :if (($char4 < 0x80) or ($char4 > 0xBF)) do={
#                        :set outstr $repch
#                        :set pos ($pos + 2)
#                    } else={
#                        :set ucsvalue ((($char1 - 0xF0) * 0x40000) + (($char2 - 0x80) * 0x1000) + \
#                                       (($char3 - 0x80) * 0x40) + ($char4 - 0x80))
#                        :set outstr "$[:pick $charsString (($ucsvalue >> 16) & 0xFF)]"
#                        :set outstr "$outstr$[:pick $charsString (($ucsvalue >> 8) & 0xFF)]$[:pick $charsString ($ucsvalue & 0xFF)]"
#                        :set pos ($pos + 3)
#                    }
#                }
#            }
#        }

        :set output "$output$outstr"
        :set pos ($pos + 1)
    }
    :return $output
}
