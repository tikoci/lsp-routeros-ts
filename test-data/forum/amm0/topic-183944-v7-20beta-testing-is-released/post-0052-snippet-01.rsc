# Source: https://forum.mikrotik.com/t/v7-20beta-testing-is-released/183944/52
# Topic: V7.20beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local rootpath "disk1/faucet"
:local ofports {"ether6";"ether7"}

:put "remove any previous faucet containers"
/interface/veth remove [find name=veth-faucet]
/ip/address remove [find comment=faucet]
:if ([:len [/container/find name=faucet]]>0) do={
    :put "...removing existing faucet container"
    :do { 
        /container stop [find name=faucet]
        :delay 31s } on-error={}
    /container remove [find name=faucet]
    :delay 2s
    /ip/address remove [find comment=faucet]
    /interface/veth remove [find name=veth-faucet]
    /openflow port remove [find switch=faucet]
    /openflow remove [find name=faucet]
}

:put "add faucet container"
/interface/veth add address=172.19.7.7/24 gateway=172.19.7.1 gateway6="" name=veth-faucet
/ip/address add address=172.19.7.1/24 interface=veth-faucet network=172.19.7.0 comment=faucet
/container add name=faucet interface=veth-faucet logging=yes root-dir=$rootpath start-on-boot=yes check-certificate=no remote-image=registry-1.docker.io/faucet/faucet:latest
:put "waiting for extract of faucet..."
:delay 60s
/container start [find name=faucet]
:delay 10s
:put "started, adding config..."

:put "setup OpenFlow"
/openflow add controllers=tcp/172.19.7.7/6653 disabled=no name=faucet verify-peer=none version=1.3 datapath-id=0/00:00:00:00:00:07
:delay 3s
:foreach p in=$ofports do={
    /openflow port add disabled=no interface=$p switch=faucet
}

:put "calculate 'dp_id' needed for faucet config"
:local dpidnum 7  
# TODO: previously the datepath-id was automatically generated... 
#    ... but getting datapath-id to a number/hex for faucet config was just too hard/annoying
#  :local dpidarr [:deserialize delimiter=":" from=dsv options=dsv.plain [:pick [/openflow/get [find] datapath-id ] 2 64]]     
#  :local dpid "0$[:pick [/openflow/get [find] datapath-id ] 0 1]"
#  :foreach h in=($dpidarr->0) do={:set dpid "$dpid$h"}
#  :local dpidnum [:convert from=hex to=num $dpid]
:put "...using $dpidnum from $[/openflow/get [find] datapath-id ]"

:put "generate a faucet config file (to be added to container)"
:local faucetConfig {
    "vlans"={
        "vlan100"={
            "vid"=100;
            "description"="untagged"
        }
    };
    "acls"={
        "allowall"={
            {
                "rule"={
                    "actions"={"allow"=1}
                }
            };
        }
    };
    "dps"={
        "routeros"={
            "dp_id"=$dpidnum;
            "hardware"="Generic";
            "drop_broadcast_source_address"=false;
            "drop_spoofed_faucet_mac"=false;
            "interfaces"={}          
        }
    }
}
:foreach p,n in=$ofports do={
    :set ($faucetConfig->"dps"->"routeros"->"interfaces"->"$[:tostr ($p+1)]") {
        "acl_in"="allowall"; 
        "name"="$n";
        "native_vlan"="vlan100"
    }
}


# uses new /container shell cmd= to add a configuration file 
# (via RouterOS array to JSON then python in container to get YAML for faucet.yaml 
:put "save default config to /tmp"
/container/shell [find name=faucet] cmd="mv /etc/faucet/*.yaml /tmp"
:delay 2s

:put "serialize faucet ROS array config into JSON"
:local jsonconf [:serialize $faucetConfig to=json options=json.pretty]
:put $jsonconf

:put ""
:put "use python inside container to get YAML, using 7.20+ new /container/shell cmd="
/container/shell [find name=faucet] cmd="echo '$jsonconf' | python -c 'import sys, yaml, json; yaml.dump(json.load(sys.stdin), sys.stdout)' > /tmp/faucet-new.yaml"
:delay 2s
/container/shell [find name=faucet] cmd="echo \"---\n\" > /etc/faucet/faucet.yaml"
/container/shell [find name=faucet] cmd="python3 -c 'import yaml, sys; d = yaml.safe_load(sys.stdin); d[\"dps\"][\"routeros\"][\"interfaces\"] = {int(k): v for k, v in d[\"dps\"][\"routeros\"][\"interfaces\"].items()}; yaml.dump(d, sys.stdout, sort_keys=False)' < /tmp/faucet-new.yaml >> /etc/faucet/faucet.yaml"

/container/shell [find name=faucet] cmd="cat /etc/faucet/faucet.yaml"
:delay 2s

:put "check and apply configuration"
/container/shell [find name=faucet] cmd="check_faucet_config /etc/faucet/faucet.yaml"
:delay 2s
/container/shell [find name=faucet] cmd="pkill -HUP -f faucet.faucet"
}
