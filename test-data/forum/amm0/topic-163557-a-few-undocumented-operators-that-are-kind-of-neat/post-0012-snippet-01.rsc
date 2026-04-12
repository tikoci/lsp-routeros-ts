# Source: https://forum.mikrotik.com/t/a-few-undocumented-operators-that-are-kind-of-neat/163557/12
# Topic: A few undocumented operators that are kind of neat.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$printHeader currmap=$currmap currpath=$currpath

    # get key
    :local kcode [/terminal/inkey]
    :local key ([:convert to=raw from=byte-array {$kcode}])

    # find in map    
    :local currval ($currmap->$key)         
    :if ([:typeof $currval]!="nil") do={
        :local currname ($currval->0)
        :local currdata ($currval->1)
        :local currtype [:typeof $currdata]
        # found array (another tree)
        :if ($currtype="array") do={
            :set currpath "$currpath \1B[1;36m> $currname\1B[0m"
            :set currmap $currdata
        }
        # found op (function) to run
        :if ($currtype="op") do={
            :put "$currpath \1B[1;31m> $currname\1B[0m"
            :local rv [$currdata]
            :put "\t# \1B[2;35m$[:pick [:tostr $rv] 0 64]\1B[0m"
        }
    } else={
        # not in map
    }
    # if no "q" in map, then assign to quit
    :if ($key~"(q|Q)") do={ :set loop false }
    # / go to top
    :if ($kcode=47) do={ :set currmap $qkeysmap; :set currpath "" }

}
:return [:nothing]
