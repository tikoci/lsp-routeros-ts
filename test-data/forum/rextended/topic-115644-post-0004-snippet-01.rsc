# Source: https://forum.mikrotik.com/t/decode-ussd-on-wap-lte-kit/115644/4
# Post author: @rextended
# Extracted from: code-block

:global hexstr2chrstr do={
    :local hexstr $1
    :local hexlen [:len $hexstr]
    :local chk1 ""
    :local chk2 ""
    :local chrstr ""
    :local lowerarray {"a"="A";"b"="B";"c"="C";"d"="D";"e"="E";"f"="F"}
    :for x from=0 to=($hexlen - 2) step=2 do={
        :set chk1 [:pick $hexstr $x ($x + 1)]
        :set chk2 [:pick $hexstr ($x + 1) ($x + 2)]
        :if ($chk1~"[a-f]") do={ :set chk1 ($lowerarray->$chk1) }
        :if ($chk2~"[a-f]") do={ :set chk2 ($lowerarray->$chk2) }
        :if (($chk1~"[^0-9A-F]") || ($chk2~"[^0-9A-F]")) do={ :set chk1 "3"; :set chk2 "F" }
        :set chrstr "$chrstr$[[:parse "(\"\\$chk1$chk2\")"]]"
    }
    :return $chrstr
}

:put [$hexstr2chrstr "417661696c61626c652042616c616e63653a205220302e3333"]
