# Source: https://forum.mikrotik.com/t/question-on-using-the-internal-zerotier-controller/181654/23
# Topic: Question on using the Internal Zerotier Controller
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ztcontroller do={
    :if ($1 = "make") do={
        :put "check zerotier instance 'zt1' is enabled"
        /zerotier
        :if ([:len [/zerotier/find]] != 1) do={:error "error - zerotier instance is not enabled"}
        :local ztinstance [find]

        :put "adding new controller..."
        /zerotier/controller
        :if ([:len [find]]>0) do={:error "error - already controller"}
        :local ztcid [add name="ztc1" instance=$ztinstance ip-range=172.27.27.10-172.27.27.20 private=yes routes=172.27.27.0/24]
        :local ztnetworkid [get $ztcid network]

        :put "adding routeros interface for itself to controller..."
        :delay 5s
        /zerotier/interface
        :local ztifaceid [add network=$ztnetworkid name="ztc-router" instance=$ztinstance]
        
        :put "authorizing interface to access controller (please wait)"
        :delay 5s
        /zerotier/controller/member
        set [find authorized=no] authorized=yes
    }
    :if ($1 = "clean") do={
        /zerotier enable [find disabled] 
        /zerotier/interface remove [find name="ztc-router"]
        /zerotier/controller remove [find] 
        /zerotier/controller/member remove [find]
    }
    :if ($1 = "print") do={
        /zerotier
        :put "\tINSTANCE"
        print detail
        :put "\tCONTROLLER"
        controller/print detail
        :put "\tLOCAL CONTROLLER MEMBERS"
        controller/member/print detail
        :put "\tINTERFACE TO ROUTER"
        interface/print detail where name="ztc-router"
        :put "\tINTERFACE IP ADDRESS"
        /ip/address/print where interface="ztc-router"
        :put "\tZEROTIER ROUTES"
        /ip/route/print where dynamic gateway="ztc-router"
    }
}

# to setup a new one, use "make" as argument & uncomment below

# $ztcontroller make

# to remove the controller, use "clean" in above instead of "make"

# always output when run
$ztcontroller print
