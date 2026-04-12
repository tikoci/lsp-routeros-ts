# Source: https://forum.mikrotik.com/t/convert-identity-name-to-uppercase/161897/6
# Post author: @rextended
# Extracted from: code-block

:global convchr do={
    :local chr $1
    :if (([:typeof $chr] != "str") or ($chr = "")) do={ :return "" }
    # ascii length > conv length because escaped " $ \ and question mark
    :local ascii " !\"#\$%&'()*+,-./0123456789:;<=>\?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    :local conv  "_____________-._0123456789_______ABCDEFGHIJKLMNOPQRSTUVWXYZ______ABCDEFGHIJKLMNOPQRSTUVWXYZ____"
    :local chrValue [:find $ascii [:pick $chr 0 1] -1]
    :if ([:typeof $chrValue] = "num") do={
        :return [:pick $conv $chrValue ($chrValue + 1)]
    } else={
        :return "_"
    }
}

:global convstr do={
    :global convchr
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :set constr "$constr$[$convchr [:pick $string $pos ($pos + 1)]]"
    }
    :return $constr
}

:put [$convstr (" !\"#\$%&'()*+,-./0123456789:;<=>\?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")]
