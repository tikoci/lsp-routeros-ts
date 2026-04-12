# Source: https://forum.mikrotik.com/t/option39-dhcpv6-client/151933/5
# Post author: @rextended
# Extracted from: code-block

:global fqdn2encdns do={
    :local charsString ""
    :for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
        :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
        :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
    } }

    :local chr2lcase do={
        :local chrValue [:find $2 $1 -1]
        :if (($chrValue > 64) and ($chrValue < 91)) do={
            :return [:pick $2 ($chrValue + 32) ($chrValue + 33)]
        } else={
            :return $1
        }
    }

    :local numbyte2hex do={
        :local input [:tonum $1]
        :local hexchars "0123456789ABCDEF"
        :local convert [:pick $hexchars (($input >> 4) & 0xF)]
        :set convert ($convert.[:pick $hexchars ($input & 0xF)])
        :return $convert
    }

    :local input "$1"
    :local fqdn ""
    :local encdns "0x01''"
    :if ($input~"^(([a-zA-Z0-9][a-zA-Z0-9-]{0,61}){0,1}[a-zA-Z]\\.){1,9}[a-zA-Z][a-zA-Z0-9-]{0,28}[a-zA-Z]\$") do={
         :for y from=0 to=([:len $input]-1) step=1 do={
             :set fqdn "$fqdn$[$chr2lcase [:pick $input $y] $charsString]"
         }
         :local workstr $fqdn
         :local dotidx  0
         :while ([:typeof [:find $workstr "." -1]] != "nil") do={
             :set dotidx [:find $workstr "." -1]
             :set encdns "$"encdns"0x$[$numbyte2hex $dotidx]'$[:pick $workstr 0 $dotidx]'"
             :set workstr [:pick $workstr ($dotidx + 1) [:len $workstr]]
         }
         :return "$"encdns"0x$[$numbyte2hex [:len $workstr]]'$workstr'0x00"
    } else={
        :return ""
    }
}
