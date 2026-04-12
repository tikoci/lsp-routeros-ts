# Source: https://forum.mikrotik.com/t/need-some-scripting-help-bounty-available/162737/2
# Topic: need some scripting help, bounty available
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:do {
    /tool fetch url="https://raw.githubusercontent.com/Winand/mikrotik-json-parser/master/JParseFunctions"
    :import JParseFunctions 
} on-error={:put "could not load JSON support - no internet?"}

### $JSON <string->parser | array->stringify>
:global JSON
:set JSON do={
    :global JSONLoads
    #:if ([:typeof $JSONLoads]="nothing") do={
    #    /tool fetch url=https://raw.githubusercontent.com/Winand/mikrotik-json-parser/master/JParseFunctions
    #    :import JParseFunctions
    #    :delay 5s
    #}
    :if ([:typeof $1]="str") do={
        :local got
        :if ([len [/file find name=$1]] > 0) do={
            :global JSONLoads
            :set $got [$JSONLoads [/file get $1 contents]]
            :return $got
        }
        :set $got [$JSONLoads $1]
        :return $got
    }
    :if ([:typeof $1]="array") do={
        :local tojson do={
            :local ret "{"
            :local firstIteration true
            :foreach k,v in=$1 do={
                if ($firstIteration) do={
                :set $ret ($ret . "\"".$k . "\":")
                } else={
                :set $ret ($ret . "," . "\"". $k . "\":")
                };
                :set $firstIteration false
                :local type [:typeof $v]
                :if ($type = "array") do={
                :set $ret ($ret . [$tojson $v])
                } else={
                :if ($type = "str" || $type = "id" || $type = "time" || $type = "ip" || $type = "ipv6") do={
                    :set $ret ($ret . "\"" . $v . "\"")
                } else {
                    :set $ret ($ret . $v )
                };
                };
            };
            :set $ret ($ret . "}")
            :return $ret;
        };
        :return [$tojson $1]
    }
    :error "Bug: Unhandled code path"
}

### YAML
:global YAML
:set YAML do={
    :global YAML
    :local ar $1
    :local lvl 0
    :local lines ""
    :if ([:typeof $level]="num") do={:set $lvl $level}
    :if ([:typeof $memo]="str") do={:set lines $memo}
    :local puttab do={
        :local r ""
        :for i from=0 to=$1 do={
            :set $r "$r  " 
        }
        :return $r
    }
    :foreach k,v in=$ar do={
        :local line
        :if ([:typeof $v]="array") do={
            :set line ([$puttab $lvl] . "$k:")
            :put "$line"
            [$YAML $v level=($lvl+1) memo=($lines)]
        } else={
            :set line ([$puttab $lvl] . "$k: $v")
            :put "$line"
        }
        #:if (!($2="as-value")) do={
        #}
        :set lines ("$lines\n$line")
        #:put "** line --> $lines"
        #:put ([$puttab $lvl] . "$k:\t\t\t#$([:typeof $v])")
        #:put ([$puttab $lvl] . "$k: $v\t\t#$([:typeof $v])")
    }
    :return $lines
}

:put [$YAML [ $JSON ([/tool/fetch url="https://wttr.in/Riga+LV?format=j2" output=user as-value]->"data")]]
