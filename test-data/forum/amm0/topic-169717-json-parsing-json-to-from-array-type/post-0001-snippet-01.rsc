# Source: https://forum.mikrotik.com/t/json-parsing-json-to-from-array-type/169717/1
# Topic: $JSON - parsing JSON to/from array type
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

### $JSON <str | array>
#   if first arg is RouterOS array type, it will convert to JSON as string
#   if arg is string, it's assumed it's JSON, so parsed into RouterOS array
#   note: nothing will be printed by default, so it must be used without something like :put [$JSON $myarray]
:global JSON
:set JSON do={
    :global JSONLoads
    :put [:typeof $JSONLoads]
    :if ([:typeof $JSONLoads]="nothing") do={
        # can comment out once file has been download, but will be downloading only once here anyway
        /tool fetch url=https://raw.githubusercontent.com/Winand/mikrotik-json-parser/master/JParseFunctions
        :import JParseFunctions
        :delay 5s
    }
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
