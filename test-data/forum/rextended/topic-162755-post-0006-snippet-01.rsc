# Source: https://forum.mikrotik.com/t/command-print-where-not-case-insensitive/162755/6
# Post author: @rextended
# Extracted from: code-block

:global strfind do={
    :local chrfind do={
        :local chr $1
        :if (([:typeof $chr] != "str") or ($chr = "")) do={ :return "" }
        :local ascii " !\"#\$%&'()*+,-./0123456789:;<=>\?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        :local conv  "====E===EEEE==E================E=UUUUUUUUUUUUUUUUUUUUUUUUUUEEEE==LLLLLLLLLLLLLLLLLLLLLLLLLLEEE="
        :local chrValue [:find $ascii [:pick $chr 0 1] -1]
        :if ([:typeof $chrValue] = "num") do={
            :local nv [:pick $conv $chrValue ($chrValue + 1)]
            :if ($nv = "=") do={:return $chr}
            :if ($nv = "E") do={:return ("\\$chr")}
            :if ($nv = "U") do={:return ("($chr|$[:pick $ascii ($chrValue+32) ($chrValue+33)])")}
            :if ($nv = "L") do={:return ("($[:pick $ascii ($chrValue-32) ($chrValue-31)]|$chr)")}
            :return "."
        } else={
            :return "."
        }
    }
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :set constr "$constr$[$chrfind [:pick $string $pos ($pos + 1)]]"
    }
    :return $constr
}


print where comment~[$strfind ("abc")]
