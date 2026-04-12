# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/27
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global fantasylist do={
    :local tstart [:timestamp]

    :local listname [:pick $0 1 255]
    :if ([:typeof $list] = "str") do={
        :set listname $list
    }
    :local lspread 4
    :if ([:typeof [:tonum $spread]] = "num") do={
        :set lspread [:tonum $spread]
    }
    :local ldensity 50 
    :if ([:typeof [:tonum $density]] = "num") do={
        :set ldensity [:tonum $density] 
    }
    :local start 169.254.0.0
    :if ([:typeof [:toip $ip]] = "ip") do={
        :set start [:toip $ip] 
    }
    :local retries 10
    :if ([:typeof [:tonum $fidelity]] = "num") do={
        :set retries [:tonum $fidelity]
    }
    :local clean true
    :if ($replace = "no") do={
        :set clean false
    } 
    :if ($1 = "help") do={
        :put "Usage:\r\n$0 [spread=$lspread] [density=$ldensity] [list=$0] [replace=yes] [ip=$start] [fidelity=$retries]"
        :put "\tspread=\t\tnum of /24's to distribute random entires over (e.g. how many / 254)"
        :put "\tdensity=\tpercentage (as int) of used address over the total range (i.e. 50 = 50% of possible IP)"
        :put "\tlist=\t\tdefault is $0 but can be any /ip/firewall/address-list"
        :put "\tip=\t\tthe first possible IP address to use (e.g. $[:tostr $start] )"
        :put "\tfidelity=\tduring IP randomization, dups can happen...\r\n\t\tso fidelity=$retries means try a new random IP $retries times\t\r\t\tbut on-error is slow, so use lower fidelity=1 to speed creation\r\n\t\t(at expense of accuracy to number of IPs requested by density=)"
        :put "\treplace=\tany previous list created by $0 is removed,\r\n\t\tuse 'replace=no' to keep an old entires in list"
        :return
    }

    :local possible (254*$lspread)
    :local howmany ($possible*$ldensity/100)

    /ip/firewall/address-list {
        :if ($clean) do={
            remove [find list=$listname]
            :put "remove\tprevious list: $listname"
        }
        :put ""
        :local numadded 0
        :for listitem from=0 to=($howmany-1) do={
            :retry max=$retries {
                :local rndip ($start + [:rndnum from=0 to=$possible])
                add address=$rndip list=$listname
                /terminal/cuu 
                :put "adding\t$rndip\tin $listname\t($($listitem+1) / $howmany)"
                :set numadded ($numadded+1)
            } on-error={
                :put "skipping number $listitem - no unique random ip after $retries tries (perhaps use fidelity=$($retries*2))\r\n"
            }
        }
        :put "done! requested $howmany and added $numadded random IPs (off by $($howmany-$numadded)) to $listname (len=$[:len [find list=$listname]]) after $([:timestamp]-$tstart)"
    }
}

# show help
$fantasylist help

# create 25 IPs (density=10 is 10%) in an address-list over 169.254.0.0/24 (spread=1 is 254 IPs)
$fantasylist spread=1 density=10

# create 645 IPs (density=1 is 1%) in an address-list over 169.254.0.0/16 (so spread=254 is /16)
$fantasylist spread=254 density=1
