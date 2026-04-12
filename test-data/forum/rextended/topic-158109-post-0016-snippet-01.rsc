# Source: https://forum.mikrotik.com/t/float-datatype/158109/16
# Post author: @rextended
# Extracted from: code-block

:global ieee754toint do={
    :local input    [:tonum "$1"]
    :local hack     0x3B9ACA00 ; # Hack, RouterOS do not support decimal numbers...
    :local isneg    ($input >> 31)
    :local exponent (($input >> 23) & 0xFF)
    :local powerof2 1
    :for x from=1 to=($exponent - 0x7F) step=1 do={:set powerof2 ($powerof2 * 2)}
    :set   exponent $powerof2
    :local mantissa ($input & 0x7FFFFF)
    :set   powerof2 $hack
    :local temp     $hack
    :for x from=22 to=5 step=-1 do={ ; # is 5 and not 0 because missing support for decimals on RouterOS
        :set powerof2 ($powerof2 / 2)
        :if ((($mantissa >> $x) & 1) = 1) do={
            :set temp ($temp + $powerof2)
        }
    }
    :set mantissa  $temp
    :local total   (($exponent * $mantissa) / $hack)
    :local decimal (($exponent * $mantissa) % $hack)
    :if ($decimal > 444444444) do={:set total ($total +1)}
    :if ($isneg = 1) do={:set total ($total * -1)}
    :return $total
}
