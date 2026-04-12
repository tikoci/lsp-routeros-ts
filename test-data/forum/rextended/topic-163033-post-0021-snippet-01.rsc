# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/21
# Post author: @rextended
# Extracted from: code-block

:global revealfields do={ :global revealfields
                          :local path "$2"
                          /system script environment
                          :foreach j in=[find] do={
                              :if ([get $j value] = $1) do={:set path "\$$[get $j name]"}
                          }
                          :put "$path BEGIN ARRAY of $[:len $1] elements"
                          :foreach x,y in=$1 do={
                              :local typex [:typeof $x]
                              :local typey [:typeof $y]
                              :local lpath $path
                              :if ($typex = "str") do={:set lpath "$path->\"$x\""} else={:set lpath "$path->$x"}
                              :if ([:typeof $y] = "array") do={
                                  :if ([:len $y] > 0) do={
                                      :put "$lpath ($typex) BEGIN ARRAY of $[:len $y] elements"
                                      [$revealfields $y $lpath]
                                      :put "$lpath ($typex) END ARRAY"
                                   } else={
                                      :put "$lpath ($typex) = [] EMPTY ARRAY"
                                   }
                              } else={
                                  :put "$lpath ($typex) = $y ($typey)"
                              }
                          }
                          :put "$path END ARRAY"
                          :return "OK"
                        }


:put [$revealfields $ArrayIN]
