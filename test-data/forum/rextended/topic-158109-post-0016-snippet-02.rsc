# Source: https://forum.mikrotik.com/t/float-datatype/158109/16
# Post author: @rextended
# Extracted from: code-block

{
:local output {18630;49152} ; # simulate the read
# a = 18630 = 0x48C6
# b = 49152 = 0xC000
# (a * 0x1000) + b = (0x48C6 * 0x10000) + 0xC000 = 0x48C60000 + 0xC0000 = 0x48C6C000 = 1220984832
:local fullvalue ((($output->0) * 0x10000) + ($output->1))
:set fullvalue [$ieee754toint $fullvalue]
:local intmw ($fullvalue / 1000)
:local decmw "00$($fullvalue % 1000)" ; :set decmw [:pick $decmw ([:len $decmw] - 3) [:len $decmw]]
:put "$intmw,$"decmw"mW"
}
407,040mW
