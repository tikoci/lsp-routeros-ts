# Source: https://forum.mikrotik.com/t/lte-sim-info/157085/19
# Topic: LTE SIM info
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global findiccids do={
    :local atstrs {"ICCID";"CCID"}
    :local atseps {"+";"!";"@";"#";"%";"\$";"*"}
        :local rv
        :local result
        :foreach cmd in=$atstrs do={
            :foreach sep in=$atseps do={
                :foreach lteif in=[find running] do={
                    :local ltename [/interface lte get $lteif name]
                    :put "Trying 'AT$sep$cmd' on $ltename"
                    :set result [/interface lte at-chat $lteif input="AT$sep$cmd" as-value]
                    :if (result~".*[0-9]{12,16}.*") do={
                        # todo: should parse out the ICCID...
                        :put "Found ICCID using 'AT$sep$cmd' on $ltename: $($result->"output")"
                    }
                }
            }
        }
        :return rv
    }
    
$findiccids
