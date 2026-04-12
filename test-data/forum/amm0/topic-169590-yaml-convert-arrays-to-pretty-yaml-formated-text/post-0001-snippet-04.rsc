# Source: https://forum.mikrotik.com/t/yaml-convert-arrays-to-pretty-yaml-formated-text/169590/1
# Topic: $YAML - convert arrays to pretty YAML-formated text
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global YAML
:global "temp-yaml-cache"
:set  "temp-yaml-cache" [:toarray ""]
:set YAML do={
    :global YAML
    :local ar $1
    :if ([:typeof $file]="str") do={
        :local cacheid [:rndstr length=16 from=ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789]
        :set ($"temp-yaml-cache"->"$cacheid") $ar 
        :execute file=$file script=":global YAML; \$YAML (\$\"temp-yaml-cache\"->\"$cacheid\"); :set (\$\"temp-yaml-cache\"->\"$cacheid\")"
        :if ($console~"yes|1|true") do={} else={ :return [:nothing] }  
    }
    :local lvl 0
    :if ([:typeof $level]="num") do={:set lvl $level}
    :local puttab do={
        :local r ""
        :if ($1=0) do={:return ""}
        :for i from=1 to=$1 do={
            :set $r "$r  " 
        }
        :return $r
    }
    :foreach k,v in=$ar do={
        :local line
        :if ([:typeof $v]="array") do={
            :local arrmark "$k:"
            :if ([:typeof "$k"]="num") do={:set arrmark "-"}
            :set line ([$puttab $lvl] . $arrmark )
            :put "$line"
            :if ([:len $v]>0) do={
                [$YAML $v level=($lvl+1)]
            }
        } else={
            :local lv $v
            :if (([:typeof $lv]="str")) do={
                if ($lv~"[\\{\\}\\,\\*#\\\?|\\-\\<\\>\\!\\%@\\\\\\:\\&]") do={
                    :if ($lv~"[\"]") do={
                      :set lv "'$lv'"  
                    } else={
                        :set lv "\"$lv\""
                    }
                } else={
                    :if ($lv~"[']") do={
                      :set lv "\"$lv\""  
                    } else={
                      :if ($lv~"[][]") do={
                        :set $lv "'$lv'"
                    } else={
                        :set lv $lv                
                      }
                    }
                }
                :if ([:tostr $lv]="") do={:set lv "\"\""}
            }
            :if ([:typeof $k]="num") do={
                :set line ([$puttab $lvl] . "- $[:tostr $lv]")
            } else={
                :set line ([$puttab $lvl] . "$[:tostr $k]: $[:tostr $lv]")
            }
            :put "$line"
        }
    }
    :return [:nothing]
}
