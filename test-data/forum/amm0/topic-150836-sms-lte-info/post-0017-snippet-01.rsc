# Source: https://forum.mikrotik.com/t/sms-lte-info/150836/17
# Topic: SMS LTE Info
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ATVAR
:set ATVAR do={
    :local checkok 1;
    :local atchatwait "yes";
    :local cmd [:tostr $1]
    :put $cmd
    :local r [/interface/lte/at-chat [find running] input="$cmd" wait=$atchatwait as-value];
    :set r ($r->"output");
    if (checkok>0) do={
        :local s [:find $r "OK"]; 
        :if (s>0) do={
            :local z [:pick $r 0 $s];
            :return [:tostr $z];
        } else={:error "ATVAR got error: $r"}
    } else={:return $r}
};

:global AT 
:set AT do={
    :global ATVAR;
    :local z [$ATVAR $1];
    :put $z;
    :return $z;
};
