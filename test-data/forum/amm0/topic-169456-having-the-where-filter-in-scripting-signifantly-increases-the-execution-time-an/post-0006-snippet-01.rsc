# Source: https://forum.mikrotik.com/t/having-the-where-filter-in-scripting-signifantly-increases-the-execution-time-and-increases-cpu-usage/169456/6
# Topic: Having the "where" filter in scripting signifantly increases the execution time and increases CPU Usage
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global getconncounts do={ 
    /ip firewall connection {
        :local startConns [:timestamp]
        :local conns [print proplist=protocol as-value]
        :local startLoop [:timestamp]
        :local counts {tcp=0;udp=0;icmp=0;other=0}
        :foreach conn in $conns do={
            :if ($conn->"protocol" = "tcp") do={
                :set ($counts->"tcp") (($counts->"tcp")+1)
            } else={
                :if ($conn->"protocol" = "udp") do={
                    :set ($counts->"udp") (($counts->"udp")+1)
                } else={
                    :if ($conn->"protocol" = "icmp") do={
                        :set ($counts->"icmp") (($counts->"icmp")+1)
                    } else={
                        :set ($counts->"other") (($counts->"other")+1)
                    }
                }
            }
        }
        :local endTime [:timestamp]
        :set ($counts->"_time_fetching") ($startLoop-$startConns)
        :set ($counts->"_time_processing") ($endTime-$startLoop)
        :set ($counts->"_time_total") ($endTime-$startConns)
        :set ($counts->"total") [:len $conns]
        :return $counts
    }
}
:global conncounts [$getconncounts]
:put $conncounts
:put "UDP: $($conncounts->"udp")"
:put "TCP: $($conncounts->"tcp")"
:put "ICMP: $($conncounts->"icmp")"
:put "other: $($conncounts->"other")"
:put "total: $($conncounts->"total")"
