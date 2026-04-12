# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/1
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global FAKEAL do={
    :local defaultlname [:pick $0 1 255]
    :local defaultspread 1
    :local defaultdensity 25
    :local defaultstart 169.254.0.0
    :local todefault  do={:if ([:typeof $1]="$2")                do={:return $1  } else={:return $3   }}
    :local invalidchr do={:if ($1~"[\24\3F\\\60\01-\19\7F-\FF]") do={:return true} else={:return false}}
    :local listname [$todefault         $list     "str" $defaultlname ]
    :local lspread  [$todefault [:tonum $spread ] "num" $defaultspread ]
    :local ldensity [$todefault [:tonum $density] "num" $defaultdensity ]
    :local lstart   [$todefault [:toip  $start  ] "ip"  $defaultstart ]
    :local lreplace  [$todefault [:tostr $replace ] "str"  true ]
    :if ([$invalidchr $listname]                   ) do={:error "list= contains invalid chars" }
    :if (($lspread  < 0) or ($lspread  > 119304647)) do={:error "spread= is out of range" }
    :if (($ldensity < 1) or ($ldensity > 100      )) do={:error "density= is out of range" }
    :if ($replace~"^(no|false|off)\$") do={:set lreplace false} else={:set lreplace true} 
    :if ($1="help") do={
        :put "Usage:"
        :put "$0 [spread=0..119304647] [density=1..100] [list=list_name] [replace={no|false|off|0}] [start=ip.ad.dr.ess]"
        :put "    spread=  num of /24's to distribute random entires over (e.g. how many / 254), default is $defaultspread (/$($defaultspread*24))"
        :put "    density= percentage (as int) of used address over the total range (i.e. 50 = 50% of possible IP), default is $defaultdensity"
        :put "    list=    default is $defaultlname but can be any valid name for /ip firewall address-list"
        :put "    start=   the first possible IP address to use, default is $defaultstart"
        :put "    replace= any previous list created by $0 is removed, use 'replace=no' to keep an old entires in list, default is yes"
        :return [:nothing]
    }

    :local possible (254*$lspread)
    :local howmany ($possible*$ldensity/100)
    :local tstart 
    :local NOW do={:do { :return [:timestamp] } on-error={ :return [/system clock get time]}}
    /ip firewall address-list {
        :put "using\taddress-list $listname"
        :if ($lreplace) do={
            :put "remove\t$listname pending"
            remove [find list=$listname]
            /terminal cuu
            :put "remove\t$listname done   "
        }
        :set tstart [$NOW]
        :put ""
        :local numadded 0
        :local skipped [:toarray ""]
        :local rndip
        :for listitem from=0 to=($possible-1) do={
            # so we loop through possible range...
            :do {
                # apply the "odds" the IP should appear...
                :local varinum [:rndnum from=0 to=(10000 / $ldensity)]
                # if :rndnum is 0... which it would be 1 out of $ldensity times
                :if ($varinum < 100) do={
                    # add an possible IP to addresss, otherwise move on without adding
                    :set rndip ($lstart + $listitem)
                    add address=$rndip list=$listname 
                    :set numadded ($numadded+1)
                    /terminal cuu 
                    :put "adding\t$((($listitem+1)*100)/($possible))%\t$rndip\t(added $numadded at $listitem of $possible)             "
                } else={
                    # DEBUG
                    #:put "rejected $rndip with $varinum"
                }
            } on-error={:set skipped ($skipped,$rndip)}
        } 
        :if ([:len $skipped] > 0) do={
            :put "skipped\t$[:len $skipped] IPs, likely because the IP was already in list"
        }
        :put "runtime\t$([:pick ([$NOW]-$tstart) 0 8])"
        :put "done!\twanted $howmany got $numadded off by $($howmany-$numadded) ($(($howmany-$numadded) * 100 / $howmany)%) in $listname (length $[:len [find list=$listname]])"
    }
}

# show help
$FAKEAL help

# create ~25 IPs (density=10 is 10%) in an address-list over 169.254.0.0/24 (spread=1 is 254 IPs)
#$FAKEAL spread=1 density=10

# create ~645 IPs (density=1 is 1%) in specific address-list ("rndvente") over 10.20.0.0 (so spread=254 is /16)
#$FAKEAL spread=254 density=1 list=rndtens start=10.20.0.0
