# Source: https://forum.mikrotik.com/t/float-datatype/158109/5
# Post author: @rextended
# Extracted from: code-block

[rex@tended] > :global float2deg do={
{...     :local float [:tonum $1]
{...     :local decimalsign "," ; # in Italy it is "," in other countries can be "."
{...     :local sign        ""  ; # if wanted can be "+"
{...     :if ($float > 32767) do={:set float (($float - 65536) * -1); :set sign "-"}
{...     :local forthousand ($float * 1000)
{...     :local forthousand ($forthousand / 256) ; # MikroTik offset
{...     :local ftstring "00$[:tostr $forthousand]"
{...     :local pickpos  ([:len $ftstring] - 3)
{...     :local decimals [:pick $ftstring $pickpos ($pickpos + [:tonum $2])]
{...     :local celsius  ($forthousand/1000)
{...     :if ([:tonum $2] > 0) do={:set celsius "$celsius$decimalsign$decimals" }
{...     :return "$sign$celsius"
{... }
[rex@tended] > :put [$float2deg 0x19a1 0]
25
[rex@tended] > :put [$float2deg 0x19a1 1]
25,6
[rex@tended] > :put [$float2deg 0x19a1 2]
25,62
[rex@tended] > :put [$float2deg 0x19a1 3]
25,628
[rex@tended] > :put [$float2deg 0xe65f 0]
-25
[rex@tended] > :put [$float2deg 0xe65f 1]
-25,6
[rex@tended] > :put [$float2deg 0xe65f 2]
-25,628
[rex@tended] > :put [$float2deg 0xe65f 3]
-25,628
