# Source: https://forum.mikrotik.com/t/how-to-resolve-an-interface-list/167253/19
# Topic: How to "resolve" an interface list?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface list add name=CHILD1 include=dynamic
/interface list add name=CHILD2 include=static
/interface list add name=ROOT include=CHILD1,CHILD2

:global RESOLVEIFLIST do={
    :global RESOLVEIFLIST
    :local iflist $1
    :local mems
    :if ([:typeof $2] = "array") do={ :set mems $2 } else={ :set mems [:toarray ""]}
    #:put $iflist
    :set iflist [/interface list get [find name=$iflist]]
    #:put $iflist
    :if ([:typeof $iflist] != "array") do={ :error "list not found" }
    :do on-error={} { 
        :set mems ($mems, [/interface list member get [find list=($iflist->"name")]]) 
    } 
    :local inc ($iflist->"include")
    :foreach imem in=$inc do={
        #:put "imem = $imem"
        :if ($imem = "dynamic") do={
            :foreach dname in=[/interface find where dynamic] do={:set mems ($mems,[/interface/get $dname name])}
        } else={
        :if ($imem = "static") do={
            :foreach dname in=[/interface find where !dynamic] do={:set mems ($mems,[/interface/get $dname name])}
        } else={
            :set mems [$RESOLVEIFLIST $imem $mems]
        }}
    }
    :return $mems
    # todo: remove exclude= ...
    # :local excl ($iflist->"exclude")
}

:put [$RESOLVEIFLIST ROOT]
