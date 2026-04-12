# Source: https://forum.mikrotik.com/t/function-to-convert-b-kib-mib-or-gib-in-a-script/155540/9
# Topic: Function to convert B, KiB, MiB or GiB in a script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global human do={
    :if ([:typeof $1]="nothing") do={
        :error "must provide a byte value to humanize";
    };
    :local input [:tonum $1]; 
    :if ([:typeof $input]!="num") do={
        :error "cannot convert $1 to number";
    };
    :local q; 
    :local r; 
    :local output;
    :if ($input<1024) do={
        :set $output "$input B";
    } else={
        :if ($input<1048576) do={
            :set q ($input/1024); 
            :set r ($input-$q*1024); 
            :set r ($r/102); 
            :set output "$q.$r KiB";
        } else={
            :if ($input<1073741824) do={
                :set q ($input/1048576); 
                :set r ($input-$q*1048576); 
                :set r ($r/104858); 
                :set output "$q.$r MiB"
            } else={
                :set q ($input/1073741824); 
                :set r ($input-$q*1073741824); 
                :set r ($r/107374182); 
                :set output "$q.$r GiB"
            }
        }
    }
	:return $output
};
