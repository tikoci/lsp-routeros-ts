# Source: https://forum.mikrotik.com/t/newb-in-scripting-getting-byte-value-from-lease-options-string/162848/4
# Post author: @rextended
# Extracted from: code-block

:global charsString ""
:for x from=0 to=15 step=1 do={ :for y from=0 to=15 step=1 do={
    :local tmpHex "$[:pick "0123456789ABCDEF" $x ($x+1)]$[:pick "0123456789ABCDEF" $y ($y+1)]"
    :set $charsString "$charsString$[[:parse "(\"\\$tmpHex\")"]]"
} }

:global chr2int do={
    :global charsString
    :if (($1="") or ([:len $1] > 1) or ([:typeof $1] = "nothing")) do={:return -1}; :return [:find $charsString $1 -1]
}

:global chr2hex do={
    :global chr2int
    :local number  [:tonum [$chr2int $1]]
    :local hexadec "0"
    :local remainder 0
    :if ($number > 0) do={:set hexadec ""}
    :while ( $number > 0 ) do={
          :set remainder ($number % 16)
          :set number (($number-$remainder) / 16)
          :set hexadec ([:pick "0123456789ABCDEF" $remainder].$hexadec)
    } 
    :if ([:len $hexadec] = 1) do={:set hexadec "0$hexadec"}
    :return "$hexadec"
}

:global str2hex do={
    :global chr2hex
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :set constr "$constr$[$chr2hex [:pick $string $pos ($pos + 1)]]"
    }
    :return $constr
}

:global str2intarr do={
    :global chr2int
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr [:toarray ""]
    :for pos from=0 to=($lenstr - 1) do={
        :set ($constr->$pos) [$chr2int [:pick $string $pos ($pos + 1)]]
    }
    :return $constr
}

:global ipv6raw2format do={
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "::" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :if ((($pos % 4) = 0) and ($pos > 0)) do={
            :set constr "$constr:$[:pick $string $pos ($pos + 1)]"
        } else={
            :set constr "$constr$[:pick $string $pos ($pos + 1)]"
        }
    }
    :return $constr
}

{
:local v212 "\0E\26\20\01\22\02\F0\00\00\00\00\00\00\00\00\00\00\00\44\2B\FF\FE"

:local hexopt [$str2hex $v212]
:put $hexopt

:local arrayopt [$str2intarr $v212]
:put $arrayopt

:put "v4 mask length $($arrayopt->0)"

:put "v6 prefix length $($arrayopt->1)"

:put "IPv6 prefix $[$ipv6raw2format [:pick $hexopt 4 36]]"

:put "6to4 6rd tunnel endpoint $(0.0.0.0 + [[:parse ":return 0x$[:pick $hexopt 36 44]"]])"
}
