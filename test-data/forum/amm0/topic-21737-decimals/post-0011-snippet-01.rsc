# Source: https://forum.mikrotik.com/t/decimals/21737/11
# Topic: Decimals ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global tofloat do={
    :global tobase;
    :local i;
    :local d;
    :local ip6comp 1000
    if ($1~"-") do={
        :set ip6comp 1001
        :set $1 [pick $1 1 99]
    }
    :if ([typeof $1]~("num")) do={
        :set $i $1; 
        :set $d 0;
    } else={ :if ([find $1 "."]>0) do={
        :set i [pick $1 0 [find $1 "."]]
        :set d [pick $1 ([find $1 "."]+1) 64]
        } else={:set $i 0; set $d 0;}
    }
    :local ihex [$tobase $i]
    :local dhex [$tobase $d]
    :local float64 [:toip6 "$ip6comp:$dhex::$ihex"]
    #:put "$ihex $dhex $i $d $float64"
    :return $float64
}

:global fromfloat do={
    :global strip
    :local float64 [tostr $1]
    :local neg ""
    :if ($float64~"1001.+") do={:set $neg "-"}
    :set $float64 [pick $float64 5 64]
    :local ipart [$strip char=":" [pick $float64 ([find $float64 "::"]+2) 64]]
    :local dpart [$strip char=":" [pick $float64 0 ([find $float64 ":"]+1)]]
    #if ([typeof [tonum $dpart]]!="num") do={set dpart 0}
    #:put "$float64 $neg $ipart $dpart"
    :set ipart [tonum "0x$ipart"]
    :set dpart [tonum "0x$dpart"]
    :local strfloat "$neg$ipart.$dpart"
    #:put "$strfloat $ipart $dpart"
    :return $strfloat
}

# adapted from msmater http://forum.mikrotik.com/t/cleaning-characters-from-string-for-use-in-variablename/139391/1
:global strip do={
    :local a [tostr $1]
    :local b $char
    :if ([typeof $b]="nil") do={:set b "-"}
    :while ([find $a $b]) do={
        :set $a ("$[:pick $a 0 ([find $a $b]) ]"."$[:pick $a ([find $a $b]+1) ([:len $a])]")}
    :return $a
}


# adapted from System_Convert-Decimal-BaseX by Randy Graham
# :put [$tobase 32 base=16]
:global tobase do={
    :local decnum $1
    :local basenum ""

    :if ([typeof $base]="nil") do={:local base 16} else={:local base}
    :if ($base>0 and $base<33) do={} else={:set $base 16}
    :local chrtable [:toarray "0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f"]
    :local chrtable ($chrtable + [:toarray "g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z"])
    :local basedigits 0
    :local basearray
    :local bw
    :local loop 1
    :while ($loop=1 ) do={
            :set bw 0
            :for c from=0 to=$basedigits step=1 do={
            :set bw ($bw*$base)
            :if ($bw=0) do={:set bw 1}
        }
        :set basearray ($basearray + [:toarray $bw])
        :set bw ($decnum/$bw)
        :if ($bw > 0) do={
            :set basedigits ($basedigits+1)
        } else={
            :set loop 0
            :set basedigits ($basedigits-1)
        }
    }
    :local dn $decnum
    :local bpv
    :for c from=$basedigits to=0 do={
        :set bpv ($dn/[:pick $basearray $c])
        :set dn ($dn-([:pick $basearray $c]*$bpv))
        :set basenum "$basenum$[:pick $chrtable $bpv]"
    }
    :return $basenum
}
