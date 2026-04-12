# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/15
# Post author: @rextended
# Extracted from: code-block

:global searchpath do={ :global searchpath
                            :local path "$4"
                            /system script environment
                            :foreach j in=[find] do={
                                :if ([get $j value] = $1) do={:set path "\$$[get $j name]"}
                            }
                            :foreach x,y in=$1 do={
                                :local lpath $path
                                :if ([:typeof $x] = "str") do={:set lpath "$path->\"$x\""} else={:set lpath "$path->$x"}
                                :if (($x = $2) and ($y = $3)) do={
                                    :return "$lpath"
                                } else={
                                    :if ([:typeof $y] = "array") do={
                                        :local ret [$searchpath $y $2 $3 $lpath]
                                        :if ($ret != "KO") do={:return $ret}
                                    }
                                }
                            }
                            :return "KO"
                      }

{
# show previous value
:put ($ArrayIN->"networkSettings"->"connections"->"LAN"->"addresses")
# show current path
:put [$searchpath $ArrayIN "addresses" "192.168.0.101/24"]
# execute the substitution of value
[[:parse (":global ArrayIN; :set ($[$searchpath $ArrayIN "addresses" "192.168.0.101/24"]) \"192.168.0.102/24\"")]]
# show new value
:put ($ArrayIN->"networkSettings"->"connections"->"LAN"->"addresses")
}
